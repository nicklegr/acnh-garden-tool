# coding: utf-8

# 交配アルゴリズム:
# https://twitter.com/AeonSake/status/1258802725145509888

# 前提:
# - 開始時点ですべての花は花が咲いている状態、水やりカウンターは0
# - 毎日全ての花に水やりを行う
# - 繁殖した花は毎日全て取り除く

require "pp"

def array_2d(r, c)
  ret = []
  r.times do
    ret << [nil] * c
  end
  ret
end

class Flower
  def initialize
    @available = false
    @counter = 0
    @is_child = false
  end

  def roll_for_breed?
    counter_percent =
      if @counter <= 3
        5
      else
        10 + (@counter - 4) * 5
      end

    # @todo visitor watering bonus

    total_percent = [ counter_percent, 100 ].min

    dice = rand(100)

    dice < total_percent
  end

  def breeded
    @available = false
    @counter = 0
  end

  attr_accessor :available, :counter, :is_child
end

class Pos
  def initialize(x, y)
    @x = x
    @y = y
  end

  attr_accessor :x, :y
end

class Field
  POS_DIFF = [
    [ -1, -1 ],
    [ -1,  0 ],
    [ -1, +1 ],
    [  0, -1 ],
    [  0, +1 ],
    [ +1, -1 ],
    [ +1,  0 ],
    [ +1, +1 ],
  ]

  def initialize(width, height)
    @width = width
    @height = height
    @field = array_2d(height, width)
    pp @field
  end

  def daily_breed
    order = []
    for y in 0...@height
      for x in 0...@width
        order << Pos.new(x, y) if flower_cell?(x, y)
      end
    end
    order.shuffle!

    order.each do |p|
      flower(p.x, p.y).available = true
    end

    order.each do |p|
      parent = flower(p.x, p.y)
      next if !parent.available
      next if !parent.roll_for_breed?

      spawn_pos = find_random_free_adjacent(p.x, p.y)
      next if !spawn_pos

      partner_pos = find_random_adjacent_partner(p.x, p.y)
      if partner_pos
        # breed
        parents = [
          parent,
          flower(partner_pos.x, partner_pos.y),
        ]
        parents.each do |e|
          e.breeded
        end

        spawn_child(spawn_pos.x, spawn_pos.y)
      else
        # duplicate
        parent.breeded
        spawn_child(spawn_pos.x, spawn_pos.y)
      end
    end
  end

  def inc_counter
    for y in 0...@height
      for x in 0...@width
        flower(x, y).counter += 1 if flower_cell?(x, y)
      end
    end
  end

  def remove_children
    for y in 0...@height
      for x in 0...@width
        @field[y][x] = nil if flower_cell?(x, y) && flower(x, y).is_child
      end
    end
  end

  def find_random_free_adjacent(x, y)
    raise if !flower_cell?(x, y)

    candidates = []
    adjacents(x, y).each do |p|
      candidates << p if empty_cell?(p.x, p.y)
    end

    candidates.sample # nil if candidates is empty
  end

  def find_random_adjacent_partner(x, y)
    raise if !flower_cell?(x, y)

    candidates = []
    adjacents(x, y).each do |p|
      next if !flower_cell?(p.x, p.y)
      next if !flower(p.x, p.y).available

      candidates << p
    end

    candidates.sample # nil if candidates is empty
  end

  def spawn_parent(x, y)
    @field[y][x] = Flower.new
  end

  def spawn_child(x, y)
    @field[y][x] = Flower.new
    @field[y][x].is_child = true
  end

  def flower(x, y)
    raise if !flower_cell?(x, y)
    @field[y][x]
  end

  def adjacents(x, y)
    positions = POS_DIFF.map do |e|
      cx = x + e[0]
      cy = y + e[1]
      in_field?(cx, cy) ? Pos.new(cx, cy) : nil
    end
    positions.compact
  end

  def in_field?(x, y)
     0 <= x && x < @width && 0 <= y && y < @height
  end

  def flower_cell?(x, y)
    !@field[y][x].nil?
  end

  def empty_cell?(x, y)
    @field[y][x].nil?
  end

  def dump
    for y in 0...@height
      str = ""
      for x in 0...@width
        if empty_cell?(x, y)
          str += "."
        elsif flower(x, y).is_child
          str += "c"
        else
          str += "P"
        end
      end
      puts str
    end
  end
end


days = 20
# runs = 100

# ペア植え
initial_layout = [
  [ 0, 0],
  [ 0, 1],

  [ 2, 0],
  [ 2, 1],

  [ 4, 0],
  [ 4, 1],

  [ 6, 0],
  [ 6, 1],

  [ 8, 0],
  [ 8, 1],

  [10, 0],
  [10, 1],

  [ 0, 3],
  [ 1, 3],

  [ 3, 3],
  [ 4, 3],

  [ 6, 3],
  [ 7, 3],

  [ 9, 3],
  [10, 3],
]

field = Field.new(11, 4)

initial_layout.each do |e|
  field.spawn_parent(e[0], e[1])
end

puts "initial_layout:"
field.dump
puts ""

days.times do |d|
  field.daily_breed

  puts "day #{d}:"
  field.dump

  field.remove_children
  field.inc_counter

  puts ""
end
