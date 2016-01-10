# This file is a part of Julia. License is MIT: http://julialang.org/license


using Base.Test


# method 'read!(::Base.LibuvStream, ::Array{UInt8, 1})'
# resizes its array argument on EOFError (and on other exceptions)
# to indicate the number of bytes actually received
let

    function test_read(_send_buf::Vector{UInt8}, _recv_buf::Vector{UInt8})
        addr = Base.InetAddr(ip"127.0.0.1", 4444)
        srv = listen(addr)

        @async try
            c = accept(srv)
            write(c, _send_buf)
            close(c)
        catch
        end
        yield()

        try
            read!(connect(addr), _recv_buf)
        finally
            close(srv)
        end
    end

    send_buf = UInt8[0,1,2]
    recv_buf = UInt8[5,5,5,5,5]
    try
        test_read(send_buf, recv_buf)
    catch x
        if isa(x,EOFError)
            @test length(recv_buf) == length(send_buf)
            @test recv_buf == send_buf
        else
            rethrow()
        end
    end

    send_buf = UInt8[0,1,2,3,4]
    recv_buf = UInt8[5,5,5]
    rb_len = length(recv_buf)
    test_read(send_buf, recv_buf)
    @test length(recv_buf) == rb_len
    @test recv_buf == send_buf[1:rb_len]
end

