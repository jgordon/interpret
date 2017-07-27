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
       '-k' '/interpret/kb/compiled',
       '-'],
    'tokenize':
      ['/interpret/ext/candc/bin/t',
       '--stdin'],
    'candc':
      ['/interpret/ext/candc/bin/soap_client',
       '--url', 'localhost:8888'],
    'boxer':
      ['/interpret/ext/candc/bin/boxer',
       '--stdin',
       '--semantics', 'tacitus',
       '--resolve', 'true',
       '--roles', 'verbnet'],
    'phillip':
      ['/interpret/ext/phillip/bin/phil',
       '-m', 'infer',
       '-k', '/interpret/kb/compiled',
       '-H',
       '-c', 'lhs=depth',
       '-c', 'ilp=weighted',
       '-c', 'sol=lpsolve']}


def run_commands(cmds, data):
    for cmd in cmds:
        try:
            p = sub.run(commands[cmd], input=data, stdout=sub.PIPE,
                        stderr=sub.PIPE)
            data = p.stdout
        except Exception as e:
            return None, 'Exception communicating with ' + cmd + '\n' + str(e)
    return data.decode(), None


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
    if err:
        return jsonify({'error': err})

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

    return graph_html(re.sub('^.+\/', '', interpret(j)['graph']))


@app.route('/interpret', methods=['POST'])
def interpret_api():
    return jsonify(interpret(request.get_json(force=True)))


def interpret(data):
    # For simplicity of code, we recompile the KB regardless of whether
    # one is passed as input.
    if 'kb' in data:
        kb = data['kb'].encode()
    else:
        kb = open('/interpret/kb/kb.lisp').read().encode()
    out, err = run_commands(['compile kb'], kb)
    if err:
        return jsonify({'error': err})

    if 's' in data:
        sent = process_text(data['s'])

        out, err = run_commands(['tokenize', 'candc', 'boxer'], sent)
        if err:
            return jsonify({'error': err})

        parse = process_boxer(out, nonmerge)
    elif 'p' in data:
        parse = data['p']
    else:
        return jsonify({'error': 'No sentence or parse found.'})

    data = parse.encode() + b'\n'
    out, err = run_commands(['phillip'], data)
    if err:
        return jsonify({'parse': parse,
                        'error': err})

    interpret = process_phillip(out)

    path = visualize_output(out)

    if path == 'error':
        return jsonify({'parse': parse,
                        'interpret': interpret,
                        'error': 'Failed to generate proof graph.'})

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
    j = json.load(open(tempfile.gettempdir() + '/' + graphname + '.json'))
    return render_template('graph.html', lf=j['parse'],
                           interpretation=j['interpret'],
                           graphname=graphname, logfile=logfile)


@app.route('/tmp/<fname>', methods=['GET'])
def tmp(fname):
    return send_from_directory(tempfile.gettempdir(), fname)


if __name__ == '__main__':
    app.run(host='0.0.0.0')
