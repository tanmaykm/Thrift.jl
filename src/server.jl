
type TSimpleServer <: TServer
    srvr_t::TServerTransport
    processor::TProcessor
    in_t::Function
    in_p::Function
    out_t::Function
    out_p::Function
end

function serve(s::TSimpleServer)
    listen(s.srvr_t)

    while true
        client = accept(s.srvr_t)
        itrans = s.in_t(client)
        otrans = s.out_t(client)
        iprot = s.in_p(in_t)
        oprot = s.out_p(out_t)

        try
            while true
                process(s.processor, iprot, oprot)
            end
        catch e
            println(e)
        end
        close(itrans)
        close(otrans)
    end
end

