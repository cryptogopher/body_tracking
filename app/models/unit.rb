class Unit < ActiveRecord::Base
  # https://en.wikipedia.org/wiki/International_System_of_Units
  enum type: {
    number: 0,
    share: 1,

    length: 10,
    mass: 11,
    time: 12,
    temperature: 13,

    volume: 20,
    density: 21,
    ndensity: 22,

    frequency: 30,
    velocity: 31,
    flow: 32,

    energy: 30,

    pressure: 40
  }
end
