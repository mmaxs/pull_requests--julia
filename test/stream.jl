# This file is a part of Julia. License is MIT: http://julialang.org/license


using Base.Test


let
    # PR#14627
    Base.connect!(sock::TCPSocket, addr::Base.InetAddr) = Base.connect!(sock, addr.host, addr.port)

    addr = Base.InetAddr(ip"127.0.0.1", 4444)
    srv = listen(addr)

    function oneshot_accept(_srv::Base.TCPServer, _send::Vector{UInt8})
        @async try
            c = accept(_srv)
            write(c, _send)
            close(c)
        end
        yield()
        nothing
    end

    # method 'read!(::Base.LibuvStream, ::Array{UInt8, 1})'
    # resizes its array argument on EOFError
    # to indicate the number of bytes actually received
    send_buf = UInt8[0,1,2]
    recv_buf = UInt8[5,5,5,5,5]
    oneshot_accept(srv, send_buf)
    c = connect(addr)
    try
        read!(c, recv_buf)
    catch x
        if isa(x,EOFError)
            @test length(recv_buf) == length(send_buf)  # receive buffer resized
            @test recv_buf == send_buf  # check up the content
        else
            rethrow()
        end
    finally
      close(c)
    end

    # test a normal (nonexceptional) case
    send_buf = UInt8[0,1,2,3,4]
    recv_buf = UInt8[5,5,5]
    recvbuf_len = length(recv_buf)
    oneshot_accept(srv, send_buf)
    c = connect(addr)
    read!(c, recv_buf)
    @test length(recv_buf) == recvbuf_len  # receive buffer's length not changed
    @test recv_buf == send_buf[1:recvbuf_len]  # check up the content
    close(c)

    close(srv)
end

