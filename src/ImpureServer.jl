module ImpureServer


using JSON, MacroTools, PyCall

# API body
# --------

"""
    @js ex

Constructs JSON `String` from JS-like syntax.
"""
macro js(ex)
    (ex isa Symbol || @capture(ex, k_:v_)) && (ex = Expr(:tuple, ex))
    @assert isexpr(ex, :tuple, :braces)
    k2vmap = map(ex.args) do x
        x isa Symbol && return (x, x)
        @assert @capture(x, k_:v_)
        return (k, v)
    end
    ex = esc(Expr(:tuple, map(((k,v),)->:($k=$v), k2vmap)...))
    ex = MacroTools.postwalk(x -> x === :null ? nothing : x, ex)
    return :(JSON.json($ex))
end

function ping_handler(data)
    @info "ping_handler: got $data"
    return isempty(data) ? "pong" : @js { data }
end

# give up to Python
# -----------------

isdefined′(syms...) = all((isdefined(@__MODULE__, sym) for sym in syms))

function give_up_to_python(host::AbstractString, port::Integer)
    @assert isdefined′(
        :ping_handler,
        # other handlers will come here ...
    ) "all the handlers (in Julia side) are not defined"

    @info "Server will listen to http://$host:$port"

    py"""
    import falcon
    import bjoern

    # helpers
    # ------

    def get_data(req):
        return req.stream.read(req.content_length or 0)

    # NOTE:
    # handleres are neeeded to be defined in toplevel, otherwise resource routers
    # can't recognize those embedded Julia functions correctly

    def ping_handler(data):
        return $ping_handler(data)

    # resources
    # ---------

    class PingResource(object):
        def on_get(self, req, resp):
            resp.body = ping_handler(get_data(req))

        def on_post(self, req, resp):
            resp.body = ping_handler(get_data(req))

    # main
    # ----

    app = falcon.API()
    app.add_route('/ping', PingResource())

    bjoern.run(wsgi_app = app, host = $host, port = $port)
    """
end

# entry point
# -----------

# TODO:
# - async initialize ?
# - distribute process listening on the same port ?
boot_server(host = get(ENV, "PYCALLSERVER_HOST", "0.0.0.0"), port = parse(Int, get(ENV, "PYCALLSERVER_PORT", "8000"))) =
    give_up_to_python(host, port)


export  boot_server

end # module
