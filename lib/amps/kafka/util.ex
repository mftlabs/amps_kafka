defmodule Amps.Kafka.Util do
  def get_kafka_auth(args, provider, env \\ "") do
    {cacertfile, certfile, keyfile} =
      if String.contains?(provider["auth"], "SSL") do
        cacertfile = Path.join(AmpsUtil.tempdir(env <> "-" <> args["name"]), "cacert")
        File.write(cacertfile, AmpsUtil.get_key(provider["cacert"], env))
        certfile = Path.join(AmpsUtil.tempdir(env <> "-" <> args["name"]), "cert")
        File.write(certfile, AmpsUtil.get_key(provider["cert"], env))
        keyfile = Path.join(AmpsUtil.tempdir(env <> "-" <> args["name"]), "key")
        File.write(keyfile, AmpsUtil.get_key(provider["key"], env))
        {cacertfile, certfile, keyfile}
      else
        {nil, nil, nil}
      end

    case provider["auth"] do
      "SASL_PLAINTEXT" ->
        [
          auth:
            {:sasl, String.to_existing_atom(provider["mechanism"]),
             username: provider["username"], password: provider["password"]}
        ]

      "SASL_SSL" ->
        [
          use_ssl: true,
          ssl_options: [
            cacertfile: cacertfile,
            certfile: certfile,
            keyfile: keyfile
          ],
          auth:
            {:sasl, String.to_existing_atom(provider["mechanism"]),
             username: provider["username"], password: provider["password"]}
        ]

      "SSL" ->
        [
          [
            use_ssl: true,
            ssl_options: [
              cacertfile: cacertfile,
              certfile: certfile,
              keyfile: keyfile
            ]
          ]
        ]

      "NONE" ->
        []
    end
  end
end
