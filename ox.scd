~defaults = { |template|
  { |overrides|
    putAll((), template, overrides)
  };
};

"synth_def_support.scd".loadRelative;
"synth_defs.scd".loadRelative;
"keyboard.scd".loadRelative;

~quiet = -60.dbamp;
~resolveEnvs = "resolve_envs.scd".loadRelative[0];
~scheduleMeasures = "schedule_measures.scd".loadRelative[0];
~initChannels = "init_channels.scd".loadRelative[0];

~free = { |name| (name: name, synthMessage: [\free]) };
