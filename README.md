impure but fast Julia API server

```julia
pkg> dev https://github.com/aviatesk/ImpureServer.jl
julia> using ImpureServer
julia> boot_server("localhost", 8000)
```

then,
```
λ> curl http://localhost:8000/ping
pong
λ> curl http://localhost:8000/ping -H 'Content-Type:application/json' -d '{"foo":"bar"}'

{"data":"{\"foo\":\"bar\"}"}
```

## why ?

- unfortunately [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) wasn't enough fast for [my use case](https://discourse.julialang.org/t/http-jl-doesnt-seem-to-be-good-at-handling-over-1k-concurrent-requests-in-comparison-to-an-alternative-in-python/38281)
- [bjoern](https://github.com/jonashaag/bjoern) ⨯ [falcon](https://falcon.readthedocs.io/en/stable/) was easy to use and relatively fast
- still I really don't want to write API logic in Python
- so this dirty solution


## license

this repository is under [MIT license](./LICENSE.md)
