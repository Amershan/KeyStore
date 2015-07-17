%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. júl. 2015 15:31
%%%-------------------------------------------------------------------
-module(http_server).
-compile(export_all).

start(Port) ->
  io:format("Http server started.~n"),
  {ok, ServerSocket} = gen_tcp:listen(Port, [binary, {packet, 0},
    {reuseaddr, true}, {active, true}]),
  server_loop(ServerSocket).

server_loop(ServerSocket) ->
  {ok, Socket} = gen_tcp:accept(ServerSocket),

  Pid = spawn(fun() -> handle_client(Socket) end),
  inet:setopts(Socket, [{packet, 0}, binary,
    {nodelay, true}, {active, true}]),
  gen_tcp:controlling_process(Socket, Pid),

  server_loop(ServerSocket).

handle_client(Socket) ->
  receive
    {tcp, Socket, Request} ->

      Packet = erlang:decode_packet(http_bin, Request, []),
      {ok, {_, Method, {_, URLPath}, _}, _} = Packet,
      Parameters = case (string:str(binary_to_list(URLPath), "?") > 0 ) of
                     true   ->
                       string:substr(binary_to_list(URLPath), string:str(binary_to_list(URLPath), "?") + 1);
                     false  ->
                       ""
                   end,
      Path = case (string:len(Parameters) > 0) of
               true   ->
                 string:substr(binary_to_list(URLPath), 1, string:str(binary_to_list(URLPath), "?") -1);
               false  ->
                 binary_to_list(URLPath)
             end,
      if
        (Method =:= 'GET') ->
          if
            (Path =:= "/additem") ->
              gen_tcp:send(Socket, header() ++ addItem());
            (Path =:= "/getalldata") ->
              Datas = keystore:getAllData("http"),
              gen_tcp:send(Socket, header() ++ getDataPage(Datas));
            (Path =:= "/getdata") ->
              Datas = keystore:getAllData("http"),
              gen_tcp:send(Socket, header() ++ getPostDataPage(Datas));
            true ->
              gen_tcp:send(Socket, header() ++ getIndex()),
              gen_tcp:close(Socket),
              io:format("closed...~n")
          end;
        (Method =:= 'POST') ->
          if
            (Path =:= "/getdata") ->
              SplitReq = [binary_to_list(X) || X <- binary:split(Request, [<<"\r\n">>], [trim, global])],
              Key = lists:flatten(lists:map(fun (Elem) ->
                case (string:str(Elem, "key") > 0) of
                  true  ->
                    string:substr(Elem, string:str(Elem, "=") +1);
                  false  ->
                    []
                end
              end, SplitReq)),
              if
              (Key =:= []) ->
              io:format("Wrong parameter ~n"),
              gen_tcp:send(Socket, header() ++ getError("Wrong parameter"));
              true ->
                Data = keystore:getData("http", Key),
                gen_tcp:send(Socket, header() ++ getDataPage(Data)),
                gen_tcp:close(Socket)
              end;
            (Path =:= "/additem") ->
                SplitReq = [binary_to_list(X) || X <- binary:split(Request, [<<"\r\n">>], [trim, global])],
                Param = lists:flatten(lists:map(fun (Elem) ->
                  case (string:str(Elem, "key") > 0) of
                    true  ->
                      Params = httpd:parse_query(Elem),
                      {value,{_K, NewKey}} = lists:keysearch("key", 1, Params),
                      {value,{_V, NewValue}} = lists:keysearch("value", 1, Params),
                      {NewKey, NewValue};
                    false  -> []
                  end
                end, SplitReq)),
                if
                  (Param =:= []) -> [];
                  true ->
                    [{Key, Value}] = Param,
                    keystore:storeKey(Key, Value)
                end,
                Datas = keystore:getAllData("http"),
                gen_tcp:send(Socket, header() ++ getDataPage(Datas));
            true  ->
              gen_tcp:send(Socket, header() ++ getIndex()),
              gen_tcp:close(Socket),
              io:format("closed...~n")
          end;
        true ->
          []
      end
  end.

header() ->
  "HTTP/1.0 200 OK\r\n" ++
    "Cache-Control: private\r\n" ++
    "Content-Type: text/html\r\n" ++
    "Connection: Close\r\n\r\n".

getHead() ->
Htmlhead =
  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
        \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">

    <html xmlns=\"http://www.w3.org/1999/xhtml\">
    <head>
        <meta name=\"generator\" content=
                \"HTML Tidy for Cygwin (vers 1st September 2004), see www.w3.org\" />

        <title>KeyStore</title>
        <style>
            #navbar div {
            text-align: center;
            }
            ul {
            list-style-type: none;
            margin: 0;
            padding: 0;
            overflow: hidden;
            display: inline-block;
            text-align: left;
            }

            li {
            float: left;
            }

            #navbar a:link, #navbar a:visited {
            display: block;
            width: 200px;
            font-weight: bold;
            color: #FFFFFF;
            background-color: #98bf21;
            text-align: center;
            padding: 4px;
            text-decoration: none;
            text-transform: uppercase;
            }

            #navbar a:hover, #navbar a:active {
            background-color: #7A991A;
            }
        </style>
    </head>
    <body>
    <div id=\"navbar\" align=\"center\">
        <ul>
            <li><a href=\"/\">Index</a></li>
            <li><a href=\"/getdata\">get a key value</a></li>
            <li><a href=\"/getalldata\">Viev KeyStore</a></li>
            <li><a href=\"/additem \">Add key</a></li>
        </ul>

    </div>",
  Htmlhead.

getIndex() ->
  Head = getHead(),
  Body =
    "<h1 align=\"center\">KeyStore</h1>
      <p>Welcome to Keystore!</p>
      <p>This page follows the minimalist style.</p>
      </body>
      </html>",

  Content = Head ++ Body,
  list_to_binary(Content).

getError(Error)  ->
  Head = getHead(),
  Body = "<h1>KeyStore Error</h1>
          <div align=\"center\">
          <p>Error:"++ Error ++"</p>
          </div>
          </body>
          </html>",
  Content = Head ++ Body,
  list_to_binary(Content).

getPostDataPage(Datas) ->
  Head = getHead(),
  SelectValues = case (string:len(Datas) > 0) of
      true  ->
      "<form action=\"getdata\" method=\"POST\">
                <select name=\"key\">
                <option value=\"default\" disabled selected>Select a key</option>" ++
      lists:map(fun(X) -> {Key, _} = X, Y="<option name= \"key\" value=\""++ Key ++"\">" ++ Key ++ "</option>", Y end, Datas)
      ++ " </select>
              <p></p>
              <input type=\"submit\" value=\"Get Value\" />";
    false ->
      "<form action=\"getdata\" method=\"POST\">
        <select name=\"key\">
        <option value=\"default\" default>No keys in the KeyStore</option>
        <input type=\"submit\" value=\"Get Value\" disabled/>"
  end,

  Body = "<h1 align=\"center\">Keystore</h1>
          <p></p>
          <p></p>
            <div align=\"center\">"
                 ++ SelectValues ++

              "</form>
            </div>
          </body>
          </html>",
  Content = Head ++ Body,
  list_to_binary(Content).


getDataPage(Datas)  ->
  Head = getHead(),
  TableRecords = lists:map(fun(X) -> {Key, Value} = X, Y="<tr><td align=\"center\">" ++ lists:flatten(Key) ++ "</td>"
    ++ "<td  align=\"center\">" ++ lists:flatten(Value) ++ "</td></tr>", Y end, Datas),
  Body = "<h1 align=\"center\">Keystore</h1>
          <p></p>
          <p></p>
          <div align=\"center\">
            <table style=\"width:50%\">
              <tr>
                <th>Key</th>
                <th>Value</th>
              </tr>" ++ TableRecords ++
              "</table>
              </div>
              </body>
              </html>",
  Content = Head ++ Body,
  list_to_binary(Content).

addItem() ->
  Head = getHead(),
  Body =
    "<h1 align=\"center\">Keystore</h1>
          <p></p>
          <p></p>
            <div align=\"center\">
              <form action=\"additem\" method='POST'>
                  Key: <input type=\"text\" name=\"key\" required><br>
                  Value: <input type=\"text\" name=\"value\" required><br>
                  <p></p>
                  <input type=\"submit\" value=\"Submit\">
              </form>
            </div>
          </body>
          </html>",
  Content = Head ++ Body,
  list_to_binary(Content).

