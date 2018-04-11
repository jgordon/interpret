#!/usr/bin/env python3

import os
import sys
import tempfile
import re
import subprocess as sub
import json
import ftfy

from flask import Flask, request, jsonify, send_file, send_from_directory, \
    render_template

from process import process_phillip, process_boxer


# Nonmerge constraints to introduce:
# - samepred: Arguments of a predicate cannot be merged.
# - sameid: Arguments of predicates with the same ID cannot be merged.
# - freqpred: Arguments of frequent predicates cannot be merged.
# - samename: None of the arguments of predicates with the same name can be
#     merged.
nonmerge = set(['sameid', 'freqpred'])

commands = {
    'compile kb':
      ['/interpret/ext/phillip/bin/phil',
       '-m', 'compile',
       '-c', 'dist=cost',
       '-c', 'tab=null',
       '-k' '/interpret/kb/compiled'],
    'tokenize':
      ['/interpret/ext/candc/bin/t',
       '--stdin'],
    'candc':
      ['/interpret/ext/candc/bin/soap_client',
       '--url', 'localhost:8888'],
    'boxer':
      ['/interpret/ext/candc/bin/boxer',
       '--stdin',
       '--elimeq', 'true',
       '--mwe', 'yes',
       '--semantics', 'tacitus',
       '--plural', 'true',
       '--resolve', 'true',
       '--roles', 'verbnet'],
    'phillip-lpsolve':
      ['/interpret/ext/phillip/bin/phil',
       '-m', 'infer',
       '-k', '/interpret/kb/compiled',
       '-H',
       '-c', 'lhs=depth',
       '-c', 'ilp=weighted',
       '-c', 'sol=lpsolve'],
    'phillip-gurobi-kbest':
      ['/interpret/ext/phillip/bin/phil',
       '-m', 'infer',
       '-k', '/interpret/kb/compiled',
       '-H',
       '-c', 'lhs=depth',
       '-c', 'ilp=weighted',
       '-c', 'sol=gurobi-kbest',
       '-p', 'max-sols-num=3'
      ]}


def run_commands(cmds, data):
    for cmd in cmds:
        try:
            p = sub.run(commands[cmd], input=data, stdout=sub.PIPE,
                        stderr=sub.PIPE)
            data = p.stdout
            err = p.stderr
        except Exception as e:
            return None, 'Exception communicating with ' + cmd + '\n' + str(e)
    return data.decode(), err.decode()


def process_text(text):
    # Fix character encoding problems and uncurl quotes.
    text = ftfy.fix_text(text)
    # Remove dashes since we can't really handle them.
    text = re.sub(' ?(--|–|—) ?', ' ', text)
    return text.encode() + b'\n'


app = Flask(__name__)


@app.route('/')
def index_html():
    return render_template('index.html')


@app.route('/parse', methods=['POST'])
def parse_api():
    data = process_text(request.get_json(force=True)['s'])

    out, err = run_commands(['tokenize', 'candc', 'boxer'], data)
    #if err:
    #    return jsonify({'error': err})

    return jsonify({'parse': process_boxer(out, nonmerge)})


@app.route('/interpret/html', methods=['POST'])
def interpret_html():
    j = {'kb': request.form['kb']}

    input_type = request.form['input_type']
    input = request.form['sent_or_lf']

    if input_type == 'sent':
        j['s'] = input
    elif input_type == 'lf':
        j['p'] = input

    try:
        interp = interpret(j)
        graph_id = re.sub('^.+\/', '', interp['graph'])
    except KeyError:
        print('Bad interpretation:', file=sys.stderr)
        print(interp, file=sys.stderr)
        return 'error'

    return graph_html(graph_id)


@app.route('/interpret', methods=['POST'])
def interpret_api():
    return jsonify(interpret(request.get_json(force=True)))


def interpret(data):
    # For simplicity of code, we recompile the KB regardless of whether
    # one is passed as input.
    if 'kb' in data and '(' in data['kb']:
        kb = data['kb'].encode()
    else:
        kb = open('/interpret/kb/kb.lisp').read().encode()

    out, err = run_commands(['compile kb'], kb)

    if 's' in data:
        sent = process_text(data['s'])

        out, err = run_commands(['tokenize', 'candc', 'boxer'], sent)
        #if err:
        #    return {'error': err}

        parse = process_boxer(out, nonmerge)
    elif 'p' in data:
        parse = data['p']
    else:
        return {'error': 'No sentence or parse found.'}

    cmd = 'phillip-lpsolve'
    if os.path.isfile('/interpret/ext/gurobi/license/gurobi.lic'):
        cmd = 'phillip-gurobi-kbest'

    data = parse.encode() + b'\n'
    out, err = run_commands([cmd], data)
    #if err:
    #    # Phillip prints trivial messages to stderr.
    #    sys.stderr.write('Running inference:\n%s\n' % err)

    interpret = process_phillip(out)

    path = visualize_output(out)

    if path == 'error':
        return {'parse': parse,
                'interpret': interpret,
                'error': 'Failed to generate proof graph.'}

    j = {'parse': parse,
         'interpret': interpret,
         'graph': request.url_root + 'graph/' + path}


    with open(tempfile.gettempdir() + '/' + path + '.json', 'w') as jout:
        json.dump(j, jout)

    return j


def visualize_output(lines):
    with tempfile.NamedTemporaryFile(mode='w', prefix='', delete=False) as temp:
        temp.writelines(lines)
        temp.flush()

        try:
            sub.run(['python', '/interpret/ext/phillip/tools/graphviz.py',
                     temp.name])
            sub.run(['dot', '-Tsvg', temp.name + '.dot',
                     '-o', temp.name + '.svg'])
            os.remove(temp.name + '.dot')
            return re.sub('.+/', '', temp.name)
        except Exception as e:
            sys.stderr.write(str(e))
            return 'error'


@app.route('/graph/<graphname>', methods=['GET'])
def graph_html(graphname):
    logfile = open(tempfile.gettempdir() + '/' + graphname).read()

    try:
        j = json.load(open(tempfile.gettempdir() + '/' + graphname + '.json'))
        parse = j['parse']
        interpret = j['interpret']
    except Exception as e:
        sys.stderr.write(str(e))

    return render_template('graph.html', lf=parse, interpretation=interpret,
                           graphname=graphname, logfile=logfile)


@app.route('/tmp/<fname>', methods=['GET'])
def tmp(fname):
    return send_from_directory(tempfile.gettempdir(), fname)


@app.route('/license', methods=['POST'])
def license():
    key = request.get_json(force=True)['license']

    try:
        os.remove('/interpret/ext/gurobi/license/gurobi.lic')
    except:
        pass

    p = sub.run(["echo '\n/interpret/ext/gurobi/license' | grbgetkey " + key],
                shell=True, stdout=sub.PIPE, stderr=sub.PIPE)

    return jsonify({'response': p.stdout.decode()})


if __name__ == '__main__':
    app.run(host='0.0.0.0')
