defmodule Amps.Services.KafkaConsumer do
  use KafkaEx.GenConsumer

  alias KafkaEx.Protocol.Fetch.Message
  alias Amps.DB
  alias Amps.Kafka.Util

  require Logger

  defmodule State do
    defstruct messages: [], calls: 0, opts: nil, env: ""
  end

  def get_spec(name, args, env \\ "") do
    provider = DB.find_one("providers", %{"_id" => args["provider"]})
    auth_opts = Util.get_kafka_auth(args, provider)

    IO.inspect(auth_opts)

    spec = %{
      id: name,
      start:
        {KafkaEx.ConsumerGroup, :start_link,
         [
           __MODULE__,
           args["name"],
           args["topics"],
           [
             uris:
               Enum.map(
                 provider["brokers"],
                 fn %{"host" => host, "port" => port} ->
                   {host, port}
                 end
               ),
             extra_consumer_args: [args, env]
           ] ++
             auth_opts
         ]}
    }

    IO.inspect(spec)
    spec
  end

  # note - messages are delivered in batches

  def init(_topic, _partition) do
    {:ok, %State{}}
  end

  def init(_topic, _partition, opts) do
    case opts do
      [args, env] ->
        {:ok, %State{opts: args, env: env}}

      [args] ->
        {:ok, %State{opts: args}}
    end
  end

  def handle_message_set(message_set, state) do
    # raise "TEST"

    for message <- message_set do
      handle_message(message, state)
    end

    {:async_commit, state}
  end

  def handle_message(msg, state) do
    opts = state.opts
    env = state.env
    msgid = AmpsUtil.get_id()
    fpath = Path.join(AmpsUtil.tempdir(msgid), msgid)

    data =
      try do
        Jason.encode!(%{"data" => msg.value})
        %{"data" => msg.value}
      rescue
        _ ->
          IO.inspect("RESCUING")
          File.write(fpath, msg.value)
          info = File.stat!(fpath)
          %{"fpath" => fpath, "fsize" => info.size}
      end

    event =
      Map.merge(
        %{
          "service" => opts["name"],
          "msgid" => msgid,
          "ktopic" => msg.topic,
          "ftime" => DateTime.to_iso8601(DateTime.utc_now())
        },
        data
      )

    {event, sid} = AmpsEvents.start_session(event, %{"service" => state.opts["name"]}, env)

    fname =
      if not AmpsUtil.blank?(opts["format"]) do
        try do
          AmpsUtil.format(opts["format"], event)
        rescue
          e ->
            opts["name"] <>
              "_" <> AmpsUtil.format("{DATETIME}", event)
        end
      else
        opts["name"] <>
          "_" <> AmpsUtil.format("{DATETIME}", event)
      end

    event = Map.merge(event, %{"fname" => fname, "user" => opts["name"]})

    Logger.info("Kafka Message Received from service #{opts["name"]} on topic #{msg.topic}")

    ktopic = Regex.replace(~r/[.>* -]/, msg.topic, "_")

    topic = "amps.svcs.#{opts["name"]}.#{ktopic}"

    AmpsEvents.send(event, %{"output" => topic}, %{}, env)

    AmpsEvents.end_session(sid, env)
    # AmpsEvents.send_history(
    #   "amps.events.messages",
    #   "message_events",
    #   Map.merge(event, %{
    #     "status" => "received"
    #   })
    # )
  end
end
