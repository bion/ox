~synthDefSupport = IdentityDictionary[
  \shaper_buf_1 -> CtkBuffer
    .new(size:1024)
    .fillWithEnv(env:
      Env(
        [-1, -0.1, -0.8, 0, 0.8, 0.1, 1],
        [1, 1, 1, 1, 1, 1].normalizeSum,
        [-3, 3, 6, -6, 1, -1]),
      wavetable: 1
    ).load,

  \expoatt_buf_1 -> CtkBuffer
    .new(size:1024)
    .fillWithEnv(env:
      Env(
        [0, 1, 0],
        [0.05, 0.95],
        \sin
      ),
      wavetable: 1
    ).load,

  \expodec_buf_1 -> CtkBuffer
    .new(size:1024)
    .fillWithEnv(env:
      Env(
        [0, 1, 0],
        [0.95, 0.05],
        \sin
      ),
      wavetable: 1
    ).load,

  \sin_buf_1 -> CtkBuffer
    .new(size:1024)
    .fillWithEnv(env:
      Env(
        [0, 1, 0],
        [0.5, 0.5],
        \sin
      ),
      wavetable: 1
    ).load
];
