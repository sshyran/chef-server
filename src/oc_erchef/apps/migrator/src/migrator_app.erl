%%%-------------------------------------------------------------------
%% @doc migrator public API
%% @end
%%%-------------------------------------------------------------------

-module(migrator_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%
% API
%
start(_StartType, _StartArgs) ->
    migrator_sup:start_link().

%
% Callbacks
%
stop(_State) ->
    ok.