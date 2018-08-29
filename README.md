# interpret

Interpret English into Hobbsian logical forms.

## Install

Dependencies for the server are handled by Docker. The client depends on
the 'click' package: `conda install click` or `pip3 install click`.

1. Build the image:
```
./build
```

2. Get a license for Gurobi for the virtual machine. Go to
   https://user.gurobi.com/download/licenses/free-academic to get a key
   and then run

```
./run-license [key]
```

The license file will be stored in the `license` directory.

## Run

Run the Docker image:

```
./run
```

Send requests using the example client:
```
./client I interrogated him.
./client -s sentence.txt
./client -p sentence_parse_lf.txt
```

Send requests as JSON:
```
curl -d '{"s": "I interrogated him."}' http://localhost:5000/interpret
```

Interpret uses the knowledge base in kb/kb.lisp, which is copied into the
Docker image when it is built. A different KB can be sent with a
particular request:
```
./client -s sentence.txt -k kb/custom.kb
```


## Acknowledgments

This work is supported by Contract W911NF-15-1-0543 with the US Defense
Advanced Research Projects Agency (DARPA).
