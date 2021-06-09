require "sdl2"

SDL2.init(SDL2::INIT_VIDEO|SDL2::INIT_EVENTS)

window = SDL2::Window.create("Raycaster", SDL2::Window::POS_UNDEFINED, SDL2::Window::POS_UNDEFINED, 640, 480, 0)
$renderer = window.create_renderer(-1, 0)

$renderer.draw_color = [0, 0, 0, 255]

$scale = 8

class Map
  def set_tile(x, y, t)
    @map[y*@w+x] = t
  end
  def initialize(w, h)
    @w = w
    @h = h
    @map = []
    for x in 0..@w-1 do
      for y in 0..@h-1 do
        @map[y*@w+x] = 1
      end
    end
    for x in 1..@w-2 do
      for y in 1..@h-2 do
        @map[y*@w+x] = 0
      end
    end
    for c in [[3,1], [5,3], [5,4], [5,5]] do
      x = c[0]
      y = c[1]
      @map[y*@w+x] = 1
    end
  end
  def pair_player(player)
    @player = player
  end
  def tile_at(x, y)
    if x < 0 or y < 0 or x >= @w or y >= @h then
      return -1
    end
    return @map[y*@w+x]
  end
  def draw2d
    $renderer.draw_color = [255, 255, 255, 255]
    for x in 0..@w-1 do
      for y in 0..@h-1 do
        t = @map[y*@w+x]
        if t == 1 then
          $renderer.draw_rect(SDL2::Rect.new(x*$scale, y*$scale, $scale, $scale))
        end
      end
    end
  end
  def draw3d
    $renderer.draw_color = [255, 0, 0, 255]
    for sx in 0..640-1 do
      a = @player.a - Math::PI/4 + (sx*Math::PI/2)/640
      d = 0
      x = 0
      y = 0
      for ld in 1..20*$scale do
        d = ld
        x = @player.x + Math.cos(a)*d
        y = @player.y + Math.sin(a)*d
        if tile_at((x/8).floor, (y/8).floor) != 0 then
          break
        end
      end
      if x.floor % $scale == 0 then
        $renderer.draw_color = [255, 0, 0, 255]
      elsif y.ceil % $scale == 0 then
        $renderer.draw_color = [0, 255, 0, 255]
      elsif x.ceil % $scale == 0 then
        $renderer.draw_color = [255, 0, 0, 255]
      elsif y.floor % $scale == 0 then
        $renderer.draw_color = [0, 255, 0, 255]
      end
      h = 480/d/Math.cos(@player.a-a)*10
      if h < 0 then h = 0 end
      $renderer.draw_line(sx, 240-h/2, sx, 240+h/2)
    end
  end
end

class Player
  def initialize(x, y, map)
    @x = x*$scale+$scale*0.5
    @y = y*$scale+$scale*0.5
    @a = Math::PI
    @map = map
  end
  def turn(v)
    @a += v
    if @a < 0 then @a += Math::PI*2 end
    if @a > Math::PI*2 then @a -= Math::PI*2 end
  end
  def move(v)
    dx = @x + Math.cos(@a)*v
    dy = @y + Math.sin(@a)*v
    if @map.tile_at((dx/$scale).floor, (dy/$scale).floor) != 0 then
      return
    end
    @x = dx
    @y = dy
  end
  def draw2d
    $renderer.draw_color = [255, 255, 255, 255]
    v = [
      @x+Math.cos(@a)*$scale/2, @y+Math.sin(@a)*$scale/2,
      @x-Math.cos(@a-0.6)*$scale/2, @y-Math.sin(@a-0.6)*$scale/2,
      @x, @y,
      @x-Math.cos(@a+0.6)*$scale/2, @y-Math.sin(@a+0.6)*$scale/2,
    ]
    for i in 0..2 do
      $renderer.draw_line(v[i*2], v[i*2+1], v[i*2+2], v[i*2+3])
    end
    $renderer.draw_line(v[6], v[7], v[0], v[1])
  end
  def a
    @a
  end
  def x
    @x
  end
  def y
    @y
  end
end

$map = Map.new(15, 12)
$player = Player.new(1, 1, $map)
$map.pair_player($player)

def draw
  $renderer.draw_color = [0, 0, 0, 255]
  $renderer.clear
  $map.draw3d
  $map.draw2d
  $player.draw2d
  $renderer.present
end

quit = false
last_update = SDL2.get_ticks
pmv = 0
pav = 0
while not quit do
  while event = SDL2::Event.poll
    case event
    when SDL2::Event::Quit
      quit = true
    when SDL2::Event::KeyDown
      case event.sym
      when SDL2::Key::UP
        pmv = 1.2
      when SDL2::Key::DOWN
        pmv = -1.2
      when SDL2::Key::LEFT
        pav = -0.07
      when SDL2::Key::RIGHT
        pav = 0.07
      when SDL2::Key::ESCAPE
        quit = true
      end
    when SDL2::Event::KeyUp
      case event.sym
      when SDL2::Key::UP, SDL2::Key::DOWN
        pmv = 0
      when SDL2::Key::LEFT, SDL2::Key::RIGHT
        pav = 0
      end
    end
  end
  current_time = SDL2.get_ticks
  if current_time - last_update > 20 then
    $player.turn(pav)
    $player.move(pmv)
    draw
    last_update = current_time
  end
end
