defmodule Amps.Kafka do
  def ui(collection) do
    ui = %{
      "actions" => """
      (function() {
        return {
          kafkaput: {
            field: "kafkaput",
            label: "Kafka PUT",
            fields: [
              amfutil.dynamicCreate(
                amfutil.combo(
                  "Kafka Provider",
                  "provider",
                  amfutil.createCollectionStore("providers", {
                    type: "kafka",
                  }),
                  "_id",
                  "name",
                  {
                    tooltip:
                      "The configured provider with broker and authenticiation configuration.",
                  }
                ),
                "providers"
              ),
              {
                xtype: "textfield",
                fieldLabel: "Topic",
                name: "topic",
                allowBlank: false,
                tooltip:
                  "The Kafka topic to which the message should be delivered",
              },
            ]
          }
        }
      })();
      """,
      "providers" => """
      (function() {
        return {
          kafka: {
            field: "kafka",
            label: "Kafka",
            fields: [
              amfutil.infoBlock(
                "A list of Kafka brokers to connect to, provided in host-port pairs."
              ),
              {
                xtype: "arrayfield",
                name: "brokers",
                title: "Brokers",

                arrayfield: "Broker",
                arrayfields: [
                  {
                    xtype: "textfield",
                    name: "host",
                    fieldLabel: "Host",
                    vtype: "ipandhostname",
                  },
                  {
                    xtype: "numberfield",
                    name: "port",
                    fieldLabel: "Port",
                    minValue: 1,
                  },
                ],
              },
              {
                xtype: "radiogroup",
                fieldLabel: "Authentication",
                name: "auth",
                allowBlank: false,
                columns: 2,
                vertical: true,
                tooltip: "The Kafka authentication method",
                items: [
                  { boxLabel: "None", name: "auth", inputValue: "NONE" },
                  {
                    boxLabel: "SASL_PLAINTEXT",
                    name: "auth",
                    inputValue: "SASL_PLAINTEXT",
                  },
                  {
                    boxLabel: "SASL_SSL",
                    name: "auth",
                    inputValue: "SASL_SSL",
                  },
                  {
                    boxLabel: "SSL",
                    name: "auth",
                    inputValue: "SSL",
                  },
                ],
                listeners: amfutil.renderListeners(function (scope, val) {
                  if (typeof val === "object" && val !== null) {
                    val = val.auth || "";
                  }

                  var sasl = scope.up("form").down("#sasl");
                  var ssl = scope.up("form").down("#ssl");

                  sasl.setHidden(!val.includes("SASL"));
                  sasl.setDisabled(!val.includes("SASL"));

                  ssl.setHidden(!val.includes("SSL"));
                  ssl.setDisabled(!val.includes("SSL"));
                }),
              },
              {
                xtype: "fieldcontainer",
                itemId: "sasl",
                layout: {
                  type: "vbox",
                  align: "stretch",
                },
                items: [
                  amfutil.localCombo(
                    "SASL Mechanism",
                    "mechanism",
                    [
                      { field: "Plain", value: "plain" },
                      { value: "scram_sha_256", field: "SCRAM SHA 256" },
                      { value: "scram_sha_512", field: "SCRAM SHA 512" },
                    ],
                    "value",
                    "field",
                    {
                      itemId: "sasl-mech",
                      tooltip: "The SASL Mechanism for SASL Auth",
                    }
                  ),
                  {
                    itemId: "sasl-username",
                    allowBlank: false,

                    xtype: "textfield",
                    name: "username",
                    fieldLabel: "Username",
                    tooltip: "The Username for SASL Auth",
                  },
                  {
                    itemId: "sasl-password",
                    allowBlank: false,

                    xtype: "textfield",
                    name: "password",
                    fieldLabel: "Password",
                    tooltip: "The Password for SASL Auth",
                  },
                ],
              },

              {
                xtype: "fieldcontainer",
                itemId: "ssl",
                layout: {
                  type: "vbox",
                  align: "stretch",
                },
                items: [
                  amfutil.loadKey(
                    "Certificate Authority Certificate",
                    "cacert",
                    {
                      tooltip:
                        "The Certificate Authority Certificate for SSL Auth",
                    }
                  ),
                  amfutil.loadKey("Client Certificate", "cert", {
                    tooltip: "The Client Certificate for SSL Auth",
                  }),
                  amfutil.loadKey("Client Key", "key", {
                    tooltip: "The Client Key for SSL Auth",
                  }),
                ],
              },
            ],
            process: function (form) {
              var values = form.getValues();
              console.log(values);
              values.brokers = JSON.parse(values.brokers);
              return values;
            },
          }
        }
      })();
      """,
      "services" => """
      (function() {
        return {
          kafka: {
            field: "kafka",
            label: "Kafka",
            iconCls: "kafka-icon",
            combo: function (service) {
              return amfutil.localCombo(
                "Topics",
                "topicparms",
                service.topics,
                null,
                null,
                {
                  itemId: "topicparms",
                }
              );
            },
            format: function (topic) {
              var reg = /[.>* -]/;
              return topic.replace(reg, "_");
            },
            fields: [
              amfutil.dynamicCreate(
                amfutil.combo(
                  "Provider",
                  "provider",
                  amfutil.createCollectionStore("providers", { type: "kafka" }),
                  "_id",
                  "name",
                  {
                    tooltip: "The Kafka Provider to use for this service.",
                  }
                ),
                "providers"
              ),
              {
                row: true,
                xtype: "arrayfield",
                name: "topics",
                title: "Topics",
                tooltip: "The Kafka Topics to consume.",
                fieldTitle: "Topic",
                arrayfields: [
                  {
                    xtype: "textfield",
                    name: "topic",
                  },
                ],
              },
              amfutil.formatFileName(),
              {
                xtype: "checkbox",
                inputValue: true,
                checked: true,
                hidden: true,
                name: "communication",
              },
            ],
            process: function (form) {
              var values = form.getValues();
              console.log(values);
              values.topics = JSON.parse(values.topics).map(
                (topic) => topic.topic
              );
              console.log(values);
              return values;
            },
          }
        }
      })()
      """
    }

    ui[collection]
  end
end
