%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 16:23
%%%-------------------------------------------------------------------
-module(udp_server).
-author("Amershan").

%% API
-export([start_server/1, sendMessage/4]).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, Socket} = gen_udp:open(Port, [binary, {active, false}]),
    io:format("Udp server listening on port: ~p~n",[Port]),
    udpHandler(Socket)
  end),
  {ok, Pid}.


udpHandler(Socket) ->
  inet:setopts(Socket, [{active, once}]),
  receive
    {udp, Socket, CIp, CPort, BinaryMsg} ->
      io:format("UDP server received: ~p~n",[BinaryMsg]),
      ReceivedData = [binary_to_list(X) || X <- binary:split(BinaryMsg, [<<":::">>], [trim, global])],
      case lists:member("store", ReceivedData) of
        true  ->
          [_, Key, Value] = ReceivedData,
          keystore:storeKey(Key, Value),
          io:format("Data stored ~n");
        false ->  case lists:member("getData", ReceivedData) of
                    true  ->
                      [_, Key] = ReceivedData,
                      Result = keystore:getData("udp", Key),
                      gen_udp:send(Socket, CIp, CPort, Result);
                    false -> case lists:member("getAllData", ReceivedData) of
                               true ->
                                 Result = keystore:getAllData("udp"),
                                 gen_udp:send(Socket, CIp, CPort, Result);
                               false ->
                                 gen_udp:send(Socket, CIp, CPort, "Command not supported")
                             end
                  end
      end,
      udpHandler(Socket)
  end.

sendMessage(Socket, CIp, CPort, Message) ->
  gen_udp:send(Socket, CIp, CPort, Message).

