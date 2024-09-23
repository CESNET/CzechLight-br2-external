# constructs ansii color code escape sequence
def ansi(code): "\u001b[" + code + "m" + . + "\u001b[0m";

# Colorize the output based on the severity
def color($severity):
    if $severity == "critical" then . | map(ansi("31;1")) # red bold
    elif $severity == "major" then . | map(ansi("31")) # red
    elif $severity == "minor" then . | map(ansi("33")) # yellow
    elif $severity == "warning" then . | map(ansi("33;1")) # yellow bold
    else .
    end;

# Extracts resource name from /ietf-hardware xpath, if possible. In other cases, returns the input.
def formatResource:
    if(test("/ietf-hardware:hardware/component*")) then
        capture("/ietf-hardware:hardware/component\\[name='(?<resource>.*)']") | .resource
    else
        .
    end;

# Formats the alarm type and qualifier
def formatAlarmType($type;$qualifier):
    if($type == "velia-alarms:sensor-low-value-alarm") then
        "\u2103 \u23f7" # ℃ ⏷ (upwards triangle)
    elif($type == "velia-alarms:sensor-high-value-alarm") then
        "\u2103 \u23f6" # ℃ ⏶ (downwards triangle)
    elif($type == "velia-alarms:systemd-unit-failure") then
        "\u274c" # ❌
    else
        $type + " " + $qualifier
    end;

.["ietf-alarms:alarms"].["alarm-list"].["alarm"]
  | sort_by(.["severity"])
  | .[]
  | select(.["is-cleared"] == false)
  | .["perceived-severity"] as $severity
  | [
      formatAlarmType(.["alarm-type-id"];.["alarm-type-qualifier"]),
      (.["resource"] | formatResource),
      .["perceived-severity"],
      .["alarm-text"]
    ]
  | color($severity)
  | @tsv
