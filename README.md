# interpret
Interpret English into Hobbsian logical forms

Build and run the image:
```
; ./build
; ./run
```

Send requests using the example client:
```
; ./client I interrogated him.
; ./client -s sentence.txt
; ./client -p sentence_parse_lf.txt
```

Send requests as JSON:
```
; curl -d '{"s": "I interrogated him."}' http://localhost:5000/interpret
```

Interpret uses the knowledge base in kb/kb.lisp, which is copied into the
Docker image when it is built. A different KB can be sent with a
particular request:
```
; ./client -s sentence.txt -k kb/custom.kb
```
