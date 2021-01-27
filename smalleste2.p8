pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- celeste2
-- exok games

level_index,level_intro=0,0

function game_start()
  
  -- reset state
  snow,clouds,
  freeze_time,frames,seconds,minutes,shake,sfx_timer,
  berry_count,death_count,
  collected,show_score,
  camera_x,camera_y=
  {},{},
  0,0,0,0,0,0,
  0,0,
  {},0,
  0,0

  for i=0,25 do 
    add(snow,{x=rnd(132),y=rnd(132)})
    add(clouds,{x=rnd(132),y=rnd(132),s=16+rnd(32)})
  end

  -- goto titlescreen or level
  if level_index==0 then
    current_music=38
    music(current_music)
  else
    goto_level(level_index)
  end
end

function _init()
  game_start()
end

function _update()

  -- titlescreen
  if level_index==0 then
    if titlescreen_flash then
      titlescreen_flash-=1
      if titlescreen_flash<-30 then goto_level(1) end
    elseif btn(4) or btn(5) then
      titlescreen_flash=50
      sfx(22,3)
    end
  -- level intro card
  elseif level_intro>0 then
    level_intro-=1
    if level_intro==0 then psfx(17,24,9) end
  -- normal level
  else
    -- timers
    sfx_timer=max(sfx_timer-1)
    infade=min(infade+1,60)
    shake=max(shake-1)
    if level_index~=8 then
      frames+=1
      seconds+=frames\30
      minutes+=seconds\60
      seconds%=60
      frames%=30
    end

    update_input()

    --freeze
    if freeze_time>0 then
      freeze_time-=1
    else
      --objects
      for o in all(objects) do
        if o.freeze>0 then
          o.freeze-=1
        else
          o:update()
        end
        if o.destroyed then
          del(objects,o)
        end
      end
    end
  end
end

function _draw()
  pal()
  if level_index==0 then
    cls(0)
    if titlescreen_flash then
      local c=titlescreen_flash>10 and (titlescreen_flash%10<5 and 7 or 10) or titlescreen_flash>5 and 2 or titlescreen_flash>0 and 1 or 0
      if c<10 then for i=0,15 do pal(i,c) end end
    end
    sspr(72,32,56,32,36,32)
    rect(0,0,127,127,7)
    print_center("lANI'S tREK",68,14)
    print_center("a game by",80,1)
    print_center("maddy thorson",87,5)
    print_center("noel berry",94,5)
    print_center("lena raine",101,5)
    draw_snow()
    return
  end

  if level_intro>0 then
    cls()
    camera()
    draw_time(4,4)
    if level_index~=8 then
      print_center("level "..(level_index-2),56, 7)
    end
    print_center(level.title,64,7)
    return
  end

  local camera_x,camera_y=peek2(0x5f28),peek2(0x5f2a)

  if shake>0 then
    camera(camera_x-2+rnd(5),camera_y-2+rnd(5))
  end

  -- clear screen
  cls(level and level.bg or 0)

  -- draw clouds
  draw_clouds(1,0,0,1,1,level.clouds or 13,#clouds)

  -- columns
  if level.columns then
    fillp(0b0000100000000010.1)
    local x=0
    while x<level.width do
      local tx=x*8+camera_x*0.1
      rectfill(tx,0,tx+(x%2)*8+8,level.height*8,level.columns)
      x+=1+x%7
    end
    fillp()
  end

  -- draw tileset
  for x=mid(0,camera_x\8,level.width),mid(0,(camera_x+128)\8,level.width) do
    for y=mid(0,camera_y\8,level.height),mid(0,(camera_y+128)\8,level.height) do
      local tile=tile_at(x, y)
      if level.pal and fget(tile,7) then level.pal() end
      if tile~=0 and fget(tile,0) then spr(tile,x*8,y*8) end
      pal() palt()
    end
  end

  -- score
  if show_score>105 then
    rectfill(34,392,98,434,1)
    rectfill(32,390,96,432,0)
    rect(32,390,96,432,7)
    spr(21,44,396)
    ?"X "..berry_count,56,398,7
    spr(72,44,408)
    draw_time(56,408)
    spr(71,44,420)
    ?"X "..death_count,56,421,7
  end

  -- draw objects
  local p
  for o in all(objects) do
    if o.base==player then p=o else o:draw() end
  end
  if p then p:draw() end

  -- draw snow
  draw_snow()

  -- draw FG clouds
  if level.fogmode then
    if level.fogmode==1 then fillp(0b0101101001011010.1) end
    draw_clouds(1.25,0,level.height*8+1,1,0,7,#clouds-10)
    fillp()
  end

  camera()

  -- screen wipes
  -- very similar functions ... can they be compressed into one?
  if p and p.wipe_timer>5 then
    for i=0,127 do
      rectfill(0,i,191*(p.wipe_timer-5)/12-32+sin(i*0.2)*16+(127-i)*0.25,i,0)
    end
  end

  if infade<15 then
    for i=0,127 do
      rectfill(191*infade/12-32+sin(i*0.2)*16+(127-i)*0.25,i,128,i,0)
    end
  end

  -- game timer
  if infade<45 then
    draw_time(4,4)
  end

  camera(camera_x,camera_y)
end

function draw_time(x,y)
  local m,h=minutes%60,minutes\60
  rectfill(x,y,x+32,y+6,0)
  ?two_digit_str(h)..":"..two_digit_str(m)..":"..two_digit_str(seconds),x+1,y+1,7
end

function two_digit_str(x)
  return x<10 and "0"..x or x
end

function draw_clouds(scale,ox,oy,sx,sy,color,count)
  for i=1,count do
    local c=clouds[i]
    local s=c.s*scale
    local x,y=ox+(camera_x+(c.x-camera_x*0.9)%(128+s)-s/2)*sx,oy+(camera_y+(c.y-camera_y*0.9)%(128+s/2))*sy
    clip(x-s/2-camera_x,y-s/2-camera_y,s,s/2)
    circfill(x,y,s/3,color)
    if i%2==0 then
      circfill(x-s/3,y,s/5,color)
      circfill(x+s/3,y,s/6,color)
    end
    c.x+=(4-i%4)*0.25
  end
  clip(0,0,128,128)
end

function draw_snow()
  for i,s in pairs(snow) do
    circfill(camera_x+(s.x-camera_x*0.5)%132-2,camera_y+(s.y-camera_y*0.5)%132,i%2,7)
    s.x+=4-i%4
    s.y+=sin(time()*0.25+i*0.1)
  end
end

function print_center(text,y,c)
  ?text,64-2*#text-0.5,y,c
end

function approach(x,target,max_delta)
  return x<target and min(x+max_delta,target) or max(x-max_delta,target)
end

function clamp(val,low,high)
  return max(low,min(high,val))
end

function psfx(id,off,len,lock)
  if sfx_timer<=0 or lock then
    sfx(id,3,off,len)
    if lock then sfx_timer=lock end
  end
end

function draw_sine_h(x0,x1,y,col,amplitude,time_freq,x_freq,fade_x_dist)
  pset(x0,y,col)
  pset(x1,y,col)
  local x_sign,x_max,last_y,this_y=sgn(x1-x0),abs(x1-x0)-1,y
  for i=1,x_max do
    local fade=i<=fade_x_dist and i/(fade_x_dist+1) or i>x_max-fade_x_dist+1 and (x_max+1-i)/(fade_x_dist+1) or 1
    local ax,ay=x0+i*x_sign,y+sin(time()*time_freq+i*x_freq)*amplitude*fade
    pset(ax,ay+1,1)
    pset(ax,ay,col)
    this_y=ay
    while abs(ay-last_y)>1 do
      ay-=sgn(this_y-last_y)
      pset(ax-x_sign,ay+1,1)
      pset(ax-x_sign,ay,col)
    end
    last_y=this_y
  end
end

levels={
  {
    offset=0,
    width=96,
    height=16,
    camera_mode=1,
    music=38,
  },
  {
    offset=343,
    width=32,
    height=32,
    camera_mode=2,
    music=36,
    fogmode=1,
    clouds=0,
    columns=1
  },
  {
    offset=679,
    width=128,
    height=22,
    camera_mode=3,
    camera_barriers_x={38},
    camera_barrier_y=6,
    music=2,
    title="trailhead"
  },
  {
    offset=1313,
    width=128,
    height=32,
    camera_mode=4,
    music=2,
    title = "glacial caves",
    pal=function() pal(2,12) pal(5,2) end,
    columns = 1
  },
  {
    offset=2410,
    width=128,
    height=16,
    camera_mode=5,
    music=2,
    title="golden valley",
    pal=function() pal(2,14) pal(5,2) end,
    bg=13,
    clouds=15,
    fogmode=2
  },
  {
    offset=2634,
    width=128,
    height=16,
    camera_mode=6,
    camera_barriers_x={105},
    music=2,
    pal=function() pal(2,14) pal(5,2) end,
    bg=13,
    clouds=15,
    fogmode=2
  },
  {
    offset=2866,
    width=128,
    height=16,
    camera_mode=7,
    music=2,
    pal=function() pal(2,12) pal(5,2) end,
    bg=13,
    clouds=7,
    fogmode=2,
  },
  {
    offset=3056,
    width=16,
    height=62,
    title="destination",
    camera_mode=8,
    music=2,
    pal=function() pal(2, 1) pal(7, 11) end,
    bg=15,
    clouds=7,
    fogmode=2,
    right_edge=true
  }
}

function camera_x_barrier(tile_x,px,py)
  local bx=tile_x*8
  if px<bx-8 then
    camera_target_x=min(camera_target_x,bx-128)
  elseif px>bx+8 then
    camera_target_x=max(camera_target_x,bx)
  end
end

c_offset=0
camera_modes={
    -- 1: Intro
    function (px,py)
      camera_target_x=px<42 and 0 or clamp(px-48,40,level.width*8-128)
    end,
    -- 2: Intro 2
    function (px,py)
      camera_target_x,camera_target_y=px<120 and 0 or px>136 and 128 or px-64,clamp(py-64,0,level.height*8-128)
    end,
    -- 3: Level 1
    function (px,py)
      camera_target_x,camera_target_y=clamp(px-56,0,level.width*8-128),py<level.camera_barrier_y*8+3 and 0 or level.camera_barrier_y*8
      for i,b in ipairs(level.camera_barriers_x) do
        camera_x_barrier(b,px,py)
      end
    end,
    -- 4: Level 2
    function (px,py)
      if px%128>8 and px%128<120 then
        px=(px\128)*128+64
      end
      if py%128>4 and py%128<124 then
        py=(py\128)*128+64
      end
      camera_target_x,camera_target_y=clamp(px-64,0,level.width*8-128),clamp(py-64,0,level.height*8-128)
    end,
    -- 5: Level 3-1 and 3-3
    function (px,py)
      camera_target_x=clamp(px-32,0,level.width*8-128)
    end,
    -- 6: Level 3-2
    function (px,py)
      if px>848 then
        c_offset=48
      elseif px<704 then
        c_flag=false
        c_offset=32
      elseif px>808 then
        c_flag=true
        c_offset=96
      end
      camera_target_x=clamp(px-c_offset,0,level.width*8-128)
      for i,b in ipairs(level.camera_barriers_x) do
        camera_x_barrier(b,px,py)
      end
      if c_flag then
        camera_target_x=max(camera_target_x,672)
      end
    end,
    --7: Level 3-3
    function (px,py)
      c_offset=px>420 and (px<436 and px-388 or 48) or 32
      camera_target_x=clamp(px-c_offset,0,level.width*8-128)
    end,
    --8: End
    function (px,py)
      camera_target_y=clamp(py-32,0,level.height*8-128)
    end
}

function snap_camera()
  camera_x,camera_y=camera_target_x,camera_target_y
  camera(camera_x,camera_y)
end

function tile_y(py)
  return clamp(py\8,0,level.height-1)--max(0,min(py\8,level.height-1))
end

function goto_level(index)
  -- set level
  level,level_index,level_checkpoint=levels[index],index,nil

  if level.title then
    level_intro=60
  end

  if level_index==2 then 
    psfx(17,8,16)
  end

  -- load into ram
  local function vget(x,y) return peek(0x4300+x+y*level.width) end
  local function vset(x,y,v) return poke(0x4300+x+y*level.width,v) end
  px9_decomp(0,0,0x1000+level.offset,vget,vset)

  -- start music
  if current_music~=level.music and level.music then
    current_music=level.music
    music(level.music)
  end
  
  -- load level contents
  restart_level()
end

function next_level()
  level_index+=1
  goto_level(level_index)
end

function restart_level()
  camera_x,camera_y,camera_target_x,camera_target_y,
  objects,
  infade,have_grapple,sfx_timer=
  0,0,0,0,
  {},
  0,level_index>2,0

  for i=0,level.width-1 do
    for j=0,level.height-1 do
      local t=types[tile_at(i,j)]
      if t and not collected[id(i,j)] and (not level_checkpoint or t~=player) then
        create(t,i*8,j*8)
      end
    end
  end
end

-- gets the tile at the given location from the loaded level
function tile_at(x,y)
  if (x<0 or y<0 or x>=level.width or y>=level.height) then return 0 end
  return peek(0x4300+x+y*level.width)
end

input_x,input_jump_pressed,input_grapple_pressed,axis_x_value=0,0,0,0

function update_input()
    -- axes
  local prev_x=axis_x_value
  if btn(0) then
    if btn(1) then
      if axis_x_turned then
        axis_x_value,input_x=prev_x,prev_x
      else
        axis_x_turned,axis_x_value,input_x=true,-prev_x,-prev_x
      end
    else
      axis_x_turned,axis_x_value,input_x=false,-1,-1
    end
  elseif btn(1) then
    axis_x_turned,axis_x_value,input_x=false,1,1
  else
    axis_x_turned,axis_x_value,input_x=false,0,0
  end
  -- input_jump
  local jump=btn(4)
  input_jump_pressed,input_jump=jump and not input_jump and 4 or jump and max(0,input_jump_pressed-1) or 0,jump

  -- input_grapple
  local grapple=btn(5)
  input_grapple_pressed,input_grapple=grapple and not input_grapple and 4 or grapple and max(0,input_grapple_pressed-1) or 0,grapple
end

function consume_jump_press()
  local val=input_jump_pressed>0
  input_jump_pressed=0
  return val
end

function consume_grapple_press()
  local val=input_grapple_pressed>0
  input_grapple_pressed=0
  return val
end

objects,types,lookup={},{},{}
function lookup.__index(self, i) return self.base[i] end

object = {
 speed_x=0,
 speed_y=0,
 remainder_x=0,
 remainder_y=0,
 hit_x=0,
 hit_y=0,
 hit_w=8,
 hit_h=8,
 grapple_mode=0,
 hazard=0,
 facing=1,
 freeze=0
}

function object.move_x(self,x,on_collide) 
  self.remainder_x+=x
  local mx=flr(self.remainder_x+0.5)
  self.remainder_x-=mx

  local total,mxs=mx,sgn(mx)
  while mx~=0
  do
    if self:check_solid(mxs,0) then
      if on_collide then
        return on_collide(self,total-mx,total)
      end
      return true
    else
      self.x+=mxs
      mx-=mxs
    end
  end
end

function object.move_y(self,y,on_collide)
  self.remainder_y+=y
  local my=flr(self.remainder_y+0.5)
  self.remainder_y-=my
  
  local total,mys=my,sgn(my)
  local mys=sgn(my)
  while my~=0
  do
    if self:check_solid(0,mys) then
      if on_collide then
        return on_collide(self,total-my,total)
      end
      return true
    else
      self.y+=mys
      my-=mys
    end
  end
end

function object.on_collide_x(self,moved,target)
  self.remainder_x,self.speed_x=0,0
  return true
end

function object.on_collide_y(self,moved,target)
  self.remainder_y,self.speed_y=0,0
  return true
end

function object.update() end

function object.draw(self)
  spr(self.spr,self.x,self.y,1,1,self.flip_x,self.flip_y)
end

function object.overlaps(self,b,ox,oy)
  if self==b then return end
  ox,oy=ox or 0,oy or 0
  return
    ox+self.x+self.hit_x+self.hit_w>b.x+b.hit_x and
    oy+self.y+self.hit_y+self.hit_h>b.y+b.hit_y and
    ox+self.x+self.hit_x<b.x+b.hit_x+b.hit_w and
    oy+self.y+self.hit_y<b.y+b.hit_y+b.hit_h
end

function object.contains(self,px,py)
  return
    px>=self.x+self.hit_x and
    px<self.x+self.hit_x+self.hit_w and
    py>=self.y+self.hit_y and
    py<self.y+self.hit_y+self.hit_h
end

function object.check_solid(self, ox, oy)
  ox,oy=ox or 0,oy or 0
  for i=(ox + self.x + self.hit_x)\8,(ox + self.x + self.hit_x + self.hit_w-1)\8 do
    for j=tile_y(oy+self.y+self.hit_y),tile_y(oy+self.y+self.hit_y+self.hit_h-1) do
      if fget(tile_at(i, j),1) then
        return true
      end
    end
  end
  for o in all(objects) do
    if o.solid and o~=self and not o.destroyed and self:overlaps(o, ox, oy) then
      return true
    end
  end
end

function object.corner_correct(self,dir_x,dir_y,side_dist,look_ahead,only_sign,func)
  look_ahead,only_sign=look_ahead or 1,only_sign or 1
  if dir_x~=0 then
    for i=1,side_dist do
      for s=1,-2,-2 do
        if s==-only_sign then
          goto continue_x
        end
        if not self:check_solid(dir_x,i*s) and (not func or func(self,dir_x,i*s)) then
          self.x+=dir_x
          self.y+=i*s
          return true
        end
        ::continue_x::
      end
    end
  elseif dir_y~=0 then
    for i=1,side_dist do
      for s=1,-1,-2 do
        if s==-only_sign then
          goto continue_y
        end
        if not self:check_solid(i*s,dir_y) and (not func or func(self,i*s,dir_y)) then
          self.x+=i*s
          self.y+=dir_y
          return true
        end
        ::continue_y::
      end
    end
  end
end

function id(tx,ty) return level_index*100+flr(tx)+flr(ty)*128 end

function create(type,x,y)
  local obj=setmetatable({
    base=type,
    x=x,
    y=y,
    id=id(x\8,y\8)
  },lookup)
  add(objects, obj);
  (obj.init or stat)(obj)
  return obj
end

function new_type(spr)
  local obj=setmetatable({
    spr=spr,
    base=object
  },lookup)
  types[spr]=obj--add(types, obj)
  return obj
end


grapple_pickup=new_type(20)
function grapple_pickup.draw(self)
  spr(self.spr,self.x,self.y+sin(time())*2,1,1,not self.right)
end

spike_v=new_type(36)
function spike_v.init(self)
  if not self:check_solid(0,1) then
    self.flip_y,self.hazard=true,3
  else
    self.hit_y,self.hazard=5,2
  end
  self.hit_h = 3
end

spike_h=new_type(37)
function spike_h.init(self)
  if self:check_solid(-1,0) then
    self.flip_x,self.hazard=true,4
  else
    self.hit_x,self.hazard=5,5
  end
  self.hit_w=3
end

snowball=new_type(62)
snowball.grapple_mode,snowball.holdable,snowball.thrown_timer,snowball.hp=3,true,0,6
function snowball.update(self)
  if not self.held then
    self.thrown_timer -= 1
    --speed
    if self.stop then
      self.speed_x=approach(self.speed_x,0,0.25)
      if self.speed_x==0 then
        self.stop=false
      end
    else
      if self.speed_x~=0 then
        self.speed_x=approach(self.speed_x,sgn(self.speed_x)*2,0.1)
      end
    end

    --gravity
    if not self:check_solid(0,1) then
      self.speed_y=approach(self.speed_y,4,0.4)
    end

    --apply
    self:move_x(self.speed_x,self.on_collide_x)
    self:move_y(self.speed_y,self.on_collide_y)

    --bounds
    if self.y>level.height*8+24 then
      self.destroyed=true
    end
  end
end
function snowball.on_collide_x(self,moved,total)
  if self:corner_correct(sgn(self.speed_x),0,2,2,1) then
    return
  end
  if self:hurt() then
    return true
  end
  self.speed_x*=-1
  self.remainder_x,self.freeze=0,1
  psfx(17,0,2)
  return true
end
function snowball.on_collide_y(self,moved,total)
  if self.speed_y<0 then
    self.speed_y,self.remainder_y=0,0
    return true
  end
  if self.speed_y>=4 then
    self.speed_y=-2
    psfx(17,0,2)
  elseif self.speed_y>=1 then
    self.speed_y=-1
    psfx(17,0,2)
  else
    self.speed_y=0
  end
  self.remainder_y=0
  return true
end
function snowball.on_release(self,thrown)
  if not thrown then
    self.stop=true
  end
  self.thrown_timer=8
end
function snowball.hurt(self)
  self.hp-=1
  if self.hp<=0 then
    psfx(8,16,4)
    self.destroyed=true
    return true
  end
end
function snowball.bounce_overlaps(self,o)
  if self.speed_x~=0 then
    self.hit_w,self.hit_x=12,-2
    local ret=self:overlaps(o)
    self.hit_w=8
    self.hit_x=0
    return ret
  else
    return self:overlaps(o)
  end
end
function snowball.draw(self)
  pal(7,1)
  spr(self.spr,self.x,self.y+1)
  pal()
  spr(self.spr,self.x,self.y)
end

springboard=new_type(11)
springboard.grapple_mode,springboard.holdable,springboard.thrown_timer=3,true,0
function springboard.update(self)
  if not self.held then
    self.thrown_timer-=1
    --friction and gravity  
    if self:check_solid(0,1) then
      self.speed_x=approach(self.speed_x,0,1)
    else
      self.speed_x=approach(self.speed_x,0,0.2)
      self.speed_y=approach(self.speed_y,4,0.4)
    end
    --apply
    self:move_x(self.speed_x,self.on_collide_x)
    self:move_y(self.speed_y,self.on_collide_y)
    if self.player then
      self.player:move_y(self.speed_y)
    end
    self.destroyed=self.y>level.height*8+24
  end
end
function springboard.on_collide_x(self,moved,total)
  self.speed_x*=-0.2
  self.remainder_x,self.freeze=0,1
  return true
end
function springboard.on_collide_y(self,moved,total)
  if self.speed_y<0 then
    self.speed_y,self.remainder_y=0,0
    return true
  end
  if self.speed_y>=2 then
    self.speed_y*=-0.4
  else
    self.speed_y=0
  end
  self.remainder_y=0
  self.speed_x*=0.5
  return true
end
function springboard.on_release(self,thrown)
  if thrown then
    self.thrown_timer=5
  end
end

grappler=new_type(46)
grappler.grapple_mode,grappler.hit_x,grappler.hit_y,grappler.hit_w,grappler.hit_h=2,-1,-1,10,10

bridge=new_type(63)
function bridge.update(self)
  self.y+=self.falling and 3 or 0
end

berry=new_type(21)
function berry.update(self)
  if self.collected then
    self.timer+=1
    self.y-=0.2*(self.timer > 5 and 1 or 0)
    self.destroyed=self.timer > 30
  elseif self.player then
    self.x+=(self.player.x-self.x)/8
    self.y+=(self.player.y-4-self.y)/8
    self.flash-=1

    if self.player:check_solid(0,1) and self.player.state~=99 then self.ground+=1 else self.ground=0 end

    if self.ground>3 or self.player.x>level.width*8-16 or self.player.last_berry~=self then
      psfx(8,8,8,20)
      collected[self.id]=true
      berry_count+=1
      self.collected,self.timer,self.draw=true,0,score
    end
  end
end
function berry.collect(self,player)
  if not self.player then
    self.player,player.last_berry,self.flash,self.ground=player,self,5,0
    psfx(7,12,4)
  end
end
function berry.draw(self)
  if (self.timer or 0)<5 then
    grapple_pickup.draw(self)
    if (self.flash or 0)>0 then
      circ(self.x+4,self.y+4,self.flash*3,7)
      circfill(self.x+4,self.y+4,5,7)
    end
  else
    ?"1000",self.x-4,self.y+1,8
    ?"1000",self.x-4,self.y,self.timer%4<2 and 7 or 14
  end
end

crumble=new_type(19)
crumble.solid,crumble.grapple_mode=true,1
function crumble.init(self)
  self.time,self.ox,self.oy=0,self.x,self.y
end
function crumble.update(self)
  if self.breaking then
    self.time+=1
    if self.time>10 then
      self.x,self.y=-32,-32
    end
    if self.time>90 then
      self.x,self.y=self.ox,self.oy
      local can_respawn=true
      for o in all(objects) do
        if self:overlaps(o) then can_respawn=false break end
      end
      if can_respawn then
        self.breaking,self.time=false,0
        psfx(17,5,3)
      else
        self.x,self.y=-32,-32
      end
    end
  end
end
function crumble.draw(self)
  object.draw(self)
  if self.time>2 then
    fillp(0b1010010110100101.1)
    rectfill(self.x,self.y,self.x+7,self.y+7,1)
    fillp()
  end
end

checkpoint=new_type(13)
function checkpoint.init(self)
  if level_checkpoint==self.id then
    create(player,self.x,self.y)
  end
end
function checkpoint.draw(self)
  if level_checkpoint==self.id then
    sspr(104,0,1,8,self.x,self.y)
    pal(2,11)
    for i=1,7 do
      sspr(104+i,0,1,8,self.x+i,self.y+sin(-time()*2+i*0.25)*(i-1)*0.2)
    end
    pal()
  else
    object.draw(self)
  end
end

function make_spawner(tile,dir)
  local spawner=new_type(tile)
  function spawner.init(self)
    self.timer,self.spr=(self.x/8)%32,-1
  end
  function spawner.update(self)
    self.timer+=1
    if self.timer>=32 and abs(self.x-64-camera_x)<128 then
      self.timer=0
      local snowball=create(snowball,self.x,self.y-8)
      snowball.speed_x,snowball.speed_y=dir*2,4
      psfx(17,5,3)
    end
  end
  return spawner
end
snowball_spawner_r,snowball_spawner_l=make_spawner(14,1),make_spawner(15,-1)

player=new_type(2)
player.t_jump_grace,
player.t_var_jump,
player.var_jump_speed,
player.grapple_x,
player.grapple_y,
player.grapple_dir,
player.grapple_wave,
player.t_grapple_cooldown,
player.wipe_timer,
player.t_grapple_jump_grace,
player.t_grapple_pickup,
player.state=
0,0,0,0,0,0,0,0,0,0,0,0

-- Grapple Functions

--[[
  object grapple modes:
    0 - no grapple
    1 - solid
    2 - solid centered
    2 - holdable
]]

function player.start_grapple(self)
  self.state,
  self.speed_x,
  self.speed_y,
  self.remainder_x,
  self.remainder_y,
  self.grapple_x,
  self.grapple_y,
  self.grapple_wave,
  self.grapple_retract,
  self.t_grapple_cooldown,
  self.t_var_jump=
  10,0,0,0,0,self.x,self.y-3,0,false,6,0
  if input_x~=0 then
    self.grapple_dir=input_x
  else
    self.grapple_dir=self.facing
  end
  self.facing=self.grapple_dir
  psfx(8,0,5)
end

-- 0 = nothing, 1 = hit!, 2 = fail
function player.grapple_check(self,x,y)
  local tile=tile_at(x\8,tile_y(y))
  if fget(tile,1) then
    self.grapple_hit=nil
    return fget(tile,2) and 2 or 1
  end
  for o in all(objects) do
    if o.grapple_mode~=0 and o:contains(x, y) then
      self.grapple_hit=o
      return 1
    end
  end
  return 0
end

-- Helpers

function player.jump(self)
  consume_jump_press()
  self.state,
  self.speed_y,
  self.var_jump_speed,
  self.t_var_jump,
  self.t_jump_grace,
  self.auto_var_jump=
  0,-4,-4,4,0,false
  self.speed_x+=input_x*0.2
  self:move_y(self.jump_grace_y - self.y)
  psfx(7,0,4)
end

function player.bounce(self,x,y)
  self.state,
  self.speed_y,
  self.var_jump_speed,
  self.t_var_jump,
  self.t_jump_grace,
  self.auto_var_jump=
  0,-4,-4,4,0,true
  self.speed_x+=sgn(self.x-x)*0.5
  self:move_y(y-self.y) 
end

function player.spring(self,y)
  consume_jump_press()
  if input_jump then 
    psfx(17,2,3)
  else
    psfx(17,0,2)
  end
  self.state,
  self.speed_y,
  self.var_jump_speed,
  self.t_var_jump,
  self.t_jump_grace,
  self.remainder_y,
  self.auto_var_jump,
  self.springboard.player=
  0,-5,-5,6,0,0,false,nil
  for o in all(objects) do
    if o.base == crumble and not o.destroyed and self.springboard:overlaps(o, 0, 4) then
      o.breaking = true
      psfx(8, 20, 4)
    end
  end
end

function player.wall_jump(self,dir)
  consume_jump_press()
  self.state,
  self.speed_y,
  self.var_jump_speed,
  self.speed_x,
  self.t_var_jump,
  self.auto_var_jump,
  self.facing=
  0,-3,-3,3*dir,4,false,dir
  self:move_x(-dir*3)
  psfx(7,4,4)
end

function player.grapple_jump(self)
  consume_jump_press()
  psfx(17,2,3)
  self.state,
  self.t_grapple_jump_grace,
  self.speed_y,
  self.var_jump_speed,
  self.t_var_jump,
  self.auto_var_jump,
  self.grapple_retract=
  0,0,-3,-3,4,false,true
  if abs(self.speed_x)>4 then
    self.speed_x=sgn(self.speed_x)*4
  end
  self:move_y(self.grapple_jump_grace_y-self.y)
end

function player.bounce_check(self,obj)
  return self.speed_y>=0 and self.y-self.speed_y<obj.y+obj.speed_y+4
end

function player.die(self)
  self.state,freeze_time,shake=99,2,5
  death_count+=1
  psfx(14, 16, 16, 120)
end

--[[
  hazard types:
    0 - not a hazard
    1 - general hazard
    2 - up-spike
    3 - down-spike
    4 - right-spike
    5 - left-spike
]]

player.hazard_table={
  function(self) return true end, -- 1
  function(self) return self.speed_y>=0 end, -- 2
  function(self) return self.speed_y<=0 end, -- 3
  function(self) return self.speed_x<=0 end, -- 4
  function(self) return self.speed_x>=0 end -- 5
}

function player.hazard_check(self,ox,oy)
  for o in all(objects) do
    if o.hazard~=0 and self:overlaps(o,ox or 0,oy or 0) and self.hazard_table[o.hazard](self) then
      return true
    end
  end
end

function player.correction_func(self,ox,oy)
  return not self:hazard_check(ox,oy)
end

-- Grappled Objects

function pull_collide_x(self,moved,target)
  return not self:corner_correct(sgn(target),0,4,2,0)
end

function player.release_holding(self,obj,x,y,thrown)
  obj.held,obj.speed_x,obj.speed_y,self.holding=false,x,y,nil
  obj:on_release(thrown)
  psfx(7,24,6)
end

-- Events

function player.init(self)
  self.x+=4
  self.y+=8
  self.hit_x,self.hit_y,self.hit_w,self.hit_h=-3,-6,6,6
  -- scarf
  self.scarf={}
  for i=0,4 do
    add(self.scarf,{x=self.x,y=self.y})
  end
  --camera
  camera_modes[level.camera_mode](self.x,self.y)
  camera_x,camera_y=camera_target_x,camera_target_y
  camera(camera_x, camera_y)
end

function player.update(self)
  local on_ground=self:check_solid(0,1)
  if on_ground then
    self.t_jump_grace,self.jump_grace_y=4,self.y
  else
    self.t_jump_grace=max(self.t_jump_grace-1)
  end

  self.t_grapple_jump_grace=max(self.t_grapple_jump_grace-1)

  if self.t_grapple_cooldown>0 and self.state<1 then
    self.t_grapple_cooldown-=1
  end

  -- grapple retract
  if self.grapple_retract then
    self.grapple_x,self.grapple_y=approach(self.grapple_x,self.x,12),approach(self.grapple_y,self.y-3,6)
    if self.grapple_x==self.x and self.grapple_y==self.y-3 then
      self.grapple_retract = false
    end
  end

  --[[
    player states:
      0   - normal
      1 - lift
      2   - springboard bounce
      10  - throw grapple
      11  - grapple attached to solid
      12  - grapple pulling in holdable
      50  - get grapple!!
      99  - dead
      100 - finished level
  ]]

  if self.state==0 then
    -- normal state

    -- facing
    if input_x~=0 then
      self.facing=input_x
    end
    -- running
    self.speed_x=approach(
      self.speed_x,
      input_x*2,
      abs(self.speed_x)>2 and input_x==sgn(self.speed_x) and 0.1 or on_ground and 0.6 or input_x~=0 and 0.4 or 0.1
      )

    -- gravity
    if not on_ground then
      self.speed_y=min(self.speed_y+(abs(self.speed_y)<0.2 and 0.4 or 0.8),btn(3) and 5.2 or 4.5)
    end

    -- variable jumping
    if self.t_var_jump>0 then
      if input_jump or self.auto_var_jump then
        self.speed_y=self.var_jump_speed
        self.t_var_jump-=1
      else
        self.t_var_jump=0
      end
    end   

    -- jumping
    if input_jump_pressed>0 then
      if self.t_jump_grace>0 then
        self:jump()
      elseif self:check_solid(2,0) then
        self:wall_jump(-1)
      elseif self:check_solid(-2,0) then
        self:wall_jump(1)
      elseif self.t_grapple_jump_grace>0 then
        self:grapple_jump()
      end
    end

    -- throw holding
    if self.holding and not input_grapple and not self.holding:check_solid(0,-2) then
      self.holding.y-=2
      local b=btn(3)
      self:release_holding(self.holding,(b and 2 or 4)*self.facing,b and 0 or -1,not b)
    end

    -- throw grapple
    if have_grapple and not self.holding and self.t_grapple_cooldown<=0 and consume_grapple_press() then
      self:start_grapple()
    end

  elseif self.state==1 then
    -- lift state
    hold=self.grapple_hit
    hold.x,hold.y=approach(hold.x,self.x-4,4),approach(hold.y,self.y-14,4)

    if hold.x==self.x-4 and hold.y==self.y-14 then
      self.state,self.holding=0,hold
    end

  elseif self.state==2 then
    -- springboard bounce state
    self:move_x(approach(self.x,self.springboard.x+4,0.5)-self.x)
    self:move_y(approach(self.y, self.springboard.y + 4, 0.2)-self.y)
    if self.springboard.spr==11 and self.y>=self.springboard.y+2 then
      self.springboard.spr=12
    elseif self.y==self.springboard.y+4 then
      self:spring(self.springboard.y+4)
      self.springboard.spr=11
    end

  elseif self.state == 10 then
    -- throw grapple state

    -- grapple movement and hitting stuff
    for i=1,min(64-abs(self.grapple_x-self.x),6) do
      local hit=self:grapple_check(self.grapple_x+self.grapple_dir,self.grapple_y)
      if hit==0 then
        hit=self:grapple_check(self.grapple_x+self.grapple_dir,self.grapple_y-1)
      end
      if hit==0 then
        hit=self:grapple_check(self.grapple_x+self.grapple_dir,self.grapple_y+1)
      end

      local mode=self.grapple_hit and self.grapple_hit.grapple_mode or 0

      if hit==0 then
        self.grapple_x+=self.grapple_dir*2
      elseif hit==1 then
        if mode==2 then
          self.grapple_x,self.grapple_y=self.grapple_hit.x+4,self.grapple_hit.y+4
        elseif mode==3 then
          self.grapple_hit.held=true
        end

        if self.grapple_hit and self.grapple_hit.on_grappled then
          self.grapple_hit:on_grappled()
        end

        self.state,self.grapple_wave,self.grapple_boost,self.freeze=mode == 3 and 12 or 11,2,false,2
        psfx(14,0,5)
        break
      end

      if hit==0 and abs(self.grapple_x-self.x)>=64 or hit==2 then
        psfx(hit==2 and 7 or 14,8,3)
        self.grapple_retract,self.freeze,self.state=true,2,0
        break
      end
    end

    -- grapple wave
    self.grapple_wave,self.spr=approach(self.grapple_wave,1,0.2),3

    -- release
    if not input_grapple or abs(self.y-self.grapple_y)>8 then
      self.state,self.grapple_retract=0,true
      psfx(-2)
    end

  elseif self.state==11 then
    -- grapple attached state
    
    -- start boost
    if not self.grapple_boost then
      self.grapple_boost,self.speed_x=true,self.grapple_dir*8
    end

    -- acceleration
    self.speed_x,self.speed_y=approach(self.speed_x,self.grapple_dir*5,0.25),approach(self.speed_y,0,0.4)

    -- y-correction
    if self.speed_y==0 and self.y-3~=self.grapple_y then
      self:move_y(sgn(self.grapple_y-self.y+3)*0.5)
    end

    -- wall pose
    if self.spr~=4 and self:check_solid(self.grapple_dir,0) then
      self.spr=4
      psfx(14,8,3)
    end

    -- jumps
    if consume_jump_press() then
      if self:check_solid(self.grapple_dir*2,0) then
        self:wall_jump(-self.grapple_dir)
      else
        self.grapple_jump_grace_y=self.y
        self:grapple_jump()
      end
    end

    -- grapple wave
    self.grapple_wave=approach(self.grapple_wave,0,0.6)

    -- release
    if self.grapple_hit and self.grapple_hit.destroyed or not input_grapple then
      self.state,
      self.t_grapple_jump_grace,
      self.grapple_jump_grace_y,
      self.grapple_retract=
      0,2,self.y,true
      self.facing*=-1
      self.speed_x=abs(self.speed_x)>5 and sgn(self.speed_x)*5 or abs(self.speed_x)<=0.5 and 0 or self.speed_x
    end

    -- release if beyond grapple point
    if sgn(self.x-self.grapple_x)==self.grapple_dir then
      self.state=0
      if self.grapple_hit and self.grapple_hit.grapple_mode==2 then
        self.t_grapple_jump_grace,self.grapple_jump_grace_y=3,self.y
      end
      --if abs(self.speed_x)>5 then
        self.speed_x=sgn(self.speed_x)*min(5,abs(self.speed_x))
      --end
    end

  elseif self.state==12 then
    -- grapple pull state
    local obj=self.grapple_hit

    -- pull
    if obj:move_x(-self.grapple_dir*6,pull_collide_x) then
      self.state,self.grapple_retract,obj.held=0,true,false
      return
    else
      self.grapple_x=approach(self.grapple_x,self.x,6)
    end

    -- y-correct
    if obj.y~=self.y-7 then
      obj:move_y(sgn(self.y-obj.y-7)*0.5)
    end

    -- grapple wave
    self.grapple_wave=approach(self.grapple_wave,0,0.6)

    -- hold
    if self:overlaps(obj) then
      self.state=1
      psfx(7,16,6)
    end

    -- release
    if not input_grapple or abs(obj.y-self.y+7)>8 or sgn(obj.x+4-self.x)==-self.grapple_dir then
      self.state,self.grapple_retract=0,true
      self:release_holding(obj,-self.grapple_dir*5,0)--,false)
    end

  elseif self.state==50 then
    -- grapple pickup state
    self.speed_y,self.speed_x=min(self.speed_y+0.8,4.5),approach(self.speed_x,0,0.2)

    if on_ground then
      if self.t_grapple_pickup==0 then music(39) end
      if self.t_grapple_pickup==61 then music(-1) end
      if self.t_grapple_pickup==70 then music(22) end
      if self.t_grapple_pickup>80 then self.state=0 end
      self.t_grapple_pickup+=1
    end

  elseif self.state==99 or self.state==100 then
    -- dead / finished state

    if self.state==100 then
      self.x+=1
      if self.wipe_timer==5 and level_index>1 then psfx(17,24,9) end
    end

    self.wipe_timer+=1
    if self.wipe_timer>20 then
      if self.state==99 then restart_level() else next_level() end
    end
    return
  end

  -- apply
  self:move_x(self.speed_x,self.on_collide_x)
  self:move_y(self.speed_y,self.on_collide_y)

  -- holding
  if self.holding then
    self.holding.x,self.holding.y=self.x-4,self.y-14
  end

  -- sprite
  if self.state==50 and self.t_grapple_pickup>0 then
    self.spr=5
  elseif self.state~=11 then
    self.spr=not on_ground and 3 or input_x~=0 and 2+(self.spr+0.25)%2 or 2
  end

  -- object interactions
  for o in all(objects) do
    if o.base==grapple_pickup and self:overlaps(o) then
      --grapple pickup
      o.destroyed,have_grapple,self.state=true,true,50
      psfx(7,12,4)
    elseif o.base==bridge and not o.falling and self:overlaps(o) then
      --falling bridge tile
      o.falling,self.freeze,shake=true,1,2
      psfx(8,16,4)
    elseif o.base==snowball and not o.held then
      --snowball
      if self:bounce_check(o) and o:bounce_overlaps(self) then
        self:bounce(o.x+4,o.y)
        psfx(17,0,2)
        o.freeze,o.speed_y=1,-1
        o:hurt()
      elseif o.speed_x~=0 and o.thrown_timer<=0 and self:overlaps(o) then
        self:die()
        return
      end
    elseif o.base==springboard and self.state~=2 and not o.held and self:overlaps(o) and self:bounce_check(o) then
      --springboard
      self.state,
      self.speed_x,
      self.speed_y,
      self.t_jump_grace,
      self.springboard,
      self.remainder_y,
      o.player=
      2,0,0,0,o,0,self
      self:move_y(o.y+4-self.y)
    elseif o.base==berry and self:overlaps(o) then
      --berry
      o:collect(self)
    elseif o.base==crumble and not o.breaking then
      --crumble
      if self.state==0 and self:overlaps(o,0,1) then
        o.breaking=true
        psfx(8,20,4)
      elseif self.state==11 then
        if self:overlaps(o,self.grapple_dir) or self:overlaps(o,self.grapple_dir,3) or self:overlaps(o,self.grapple_dir,-2) then
          o.breaking=true
          psfx(8,20,4)
        end
      end
    elseif o.base==checkpoint and level_checkpoint~=o.id and self:overlaps(o) then
      level_checkpoint=o.id
      psfx(8,24,6,20)
    end
  end

  -- death
  if self.state<99 and (self.y>level.height*8+16 or self:hazard_check()) then
    if level_index==1 and self.x>level.width*8-64 then
      self.state,self.wipe_timer=100,-15
    else
      self:die()
    end
    return
  end

  -- bounds
  if self.y<-16 then
    self.y,self.speed_y=-16,0
  end
  if self.x<3 then
    self.x,self.speed_x=3,0
  elseif self.x>level.width*8-3 then
    if level.right_edge then
      self.x,self.speed_x=level.width*8-3,0
    else
      self.state=100
    end
  end

  -- intro bridge music
  if current_music==levels[1].music and self.x>61*8 then
    current_music=37
    music(37)
    psfx(17,24,9)
  end

  -- ending music
  if level_index==8 then
    if current_music~=40 and self.y>40 then
      current_music=40
      music(40)
    end
    if self.y>376 then show_score+=1 end
    if show_score==120 then music(38) end
  end

  -- camera
  camera_modes[level.camera_mode](self.x,self.y,on_ground)
  camera_x,camera_y=approach(camera_x,camera_target_x,5),approach(camera_y,camera_target_y,5)
  camera(camera_x,camera_y)
end

function player.on_collide_x(self, moved, target)
  if (self.state==0 and sgn(target)==input_x and self:corner_correct(input_x,0,2,2,-1,self.correction_func)) or
    (self.state==11 and self:corner_correct(self.grapple_dir,0,4,2,0,self.correction_func)) then
    return
  end
  return object.on_collide_x(self,moved,target)
end

function player.on_collide_y(self, moved, target)
  if target<0 and self:corner_correct(0,-1,2,1,input_x,self.correction_func) then
    return
  end
  self.t_var_jump=0
  return object.on_collide_y(self,moved,target)
end

function player.draw(self)

  -- death fx
  if self.state==99 then
    local e,dx,dy=self.wipe_timer/10,mid(camera_x,self.x,camera_x+128),mid(camera_y,self.y-4,camera_y+128)
    if e<=1 then
      for i=0,7 do
        circfill(dx+cos(i/8)*32*e,dy+sin(i/8)*32*e,(1-e)*8,10)
      end
    end
    return
  end

  -- scarf
  local last={x=self.x-self.facing,y=self.y-3}
  for i=1,#self.scarf do
    local s=self.scarf[i]

    -- approach last pos with an offset
    s.x+=(last.x-s.x-self.facing)/1.5
    s.y+=(last.y-s.y+sin(i*0.25+time())*i*0.25)/2

    -- don't let it get too far
    local dx,dy=s.x-last.x,s.y-last.y
    local dist=sqrt(dx*dx+dy*dy)
    if dist>1.5 then
      s.x,s.y=last.x+dx/dist*1.5,last.y+dy/dist*1.5
    end

    -- fill
    rectfill(s.x,s.y,s.x,s.y,10)
    rectfill((s.x+last.x)/2,(s.y+last.y)/2,(s.x+last.x)/2,(s.y+last.y)/2,10)
    last=s
  end

  -- grapple
  if self.state>=10 and self.state<=12 then
    draw_sine_h(self.x,self.grapple_x,self.y-3,7,2*self.grapple_wave,6,0.08,6)
  end

  -- retracting grapple
  if self.grapple_retract then
    line(self.x,self.y-2,self.grapple_x,self.grapple_y+1,1)
    line(self.x,self.y-3,self.grapple_x,self.grapple_y,7)
  end

  -- sprite
  spr(self.spr,self.x-4,self.y-8,1,1,self.facing~=1)

  if self.state==50 and self.t_grapple_pickup>0 then
    spr(20,self.x-4,self.y-18)
    for i=0,1,0.0625 do
      local a=time()*4+i
      local s,c,ty=sin(a),cos(a),self.y-14
      line(self.x+s*16,ty+c*16,self.x+s*40,ty+c*40,7)
    end
  end
end


-- px9 decompress
-- by zep

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function px9_decomp(x0,y0,src,vget,vset)
  local function vlist_val(l, val)
    -- find position
    for i=1,#l do
      if l[i]==val then
        for j=i,2,-1 do
          l[j]=l[j-1]
        end
        l[1]=val
        return i
      end
    end
  end
  -- bit cache is between 16 and 
  -- 31 bits long with the next
  -- bit always aligned to the
  -- lsb of the fractional part
  local cache,cache_bits=0,0
  function getval(bits)
    if cache_bits<16 then
      -- cache next 16 bits
      cache+=%src>>>16-cache_bits
      cache_bits+=16
      src+=2
    end
    -- clip out the bits we want
    -- and shift to integer bits
    local val=cache<<32-bits>>>16-bits
    -- now shift those bits out
    -- of the cache
    cache=cache>>>bits
    cache_bits-=bits
    return val
  end
  -- get number plus n
  function gnp(n)
    local bits=0
    repeat
      bits+=1
      local vv=getval(bits)
      n+=vv
    until vv<(1<<bits)-1
    return n
  end
  -- header
  local w,h_1,
    eb,el,pr,
    x,y,
    splen,
    predict=
    gnp"1",gnp"0",
    gnp"1",{},{},
    0,0,
    0
    --,nil

  for i=1,gnp"1" do
    add(el,getval(eb))
  end
  for y=y0,y0+h_1 do
    for x=x0,x0+w-1 do
      splen-=1
      if splen<1 then
        splen,predict=gnp"1",not predict
      end
      local a=y>y0 and vget(x,y-1) or 0
      -- create vlist if needed
      local l=pr[a]
      if not l then
        l={}
        for e in all(el) do
          add(l,e)
        end
        pr[a]=l
      end
      -- grab index from stream
      -- iff predicted, always 1
      local v=l[predict and 1 or gnp"2"]
      -- update predictions
      vlist_val(l,v)
      vlist_val(el,v)
      -- set
      vset(x,y,v)
      -- advance
      x+=1
      y+=x\w
      x%=w
    end
  end
end
__gfx__
00000000626666660011110001111110011111000011110000000000000000000000000000000000000000006666666600000000422222220000000000000000
00000000626666660111111011144411111111100111111000000000000000000000000000000000000000000311113000000000422222220800000000000080
00700700626666661114441111474471144441101174471100000000000000000000000000000000000000000031130000000000422222220080000000000800
0007700022222222114744710144444017447410714444170000000000000000000000000000000000000077000bb00000000000422222220008000000008000
00077000666662660144444000aaaa000444441007aaaa700eeeeeeeeee00000000000000000000000000777000bb00066666666200000000000808008080000
007007006666626600aaaa000022220000aaaa7000222200e111ee11e111000000770000000000000007777700b11b0000033000400000000000088008800000
000000006666626600222200070000700022220000222200e1ccee7ce7cc00000777770000000000007777770b1111b0000bb000400000000000888008880000
000000002222222200700700000000000000700007700770e1cceeccee77c0007777777000000000777777776666666666666666400000000000000000000000
57777777777777777777777599999999000600000b300b00e1cceeeceeccc0000000000000000000000000000000000000000000000000000000000000022000
77777777777777777777777791111119006660000033b000eeeeeeeeeeee22220000000000000000000000000000000000000000000000000000000000022000
77777777777777777777777791411419000500000288882088888888888897970000000000000000000000000000000000000000000000000000000000024000
77777771177777711777777791441119000500000898888088888888888897970000000000000000000000000000000000000000000000000000000000044000
777777122177771221777777911441190044400008888980eeeeeeeeeeee11110000000000000000077000000000000000000000000000000000000000044000
71777122221111222217771791414419009990000888888020002220002222220000000000000000777700000000000000000000000000000000000000044000
72111222222222222221112791111119004440000289882001610201615551000000000000000000777777000000000000000000000000000000000000044000
72222222222222222222222799999999009990000028820001110001110111000000000000000000777777700000000000000000000000000000000000042000
72222222222222222222222757777775000000000000066622222222222222225555555555555555555555555777777777777777777777750008800056666650
77222222222222222222227777777777000000000007777722222221122222225555555555555550055555557771111177711111777111170081180066666661
77222222222222222222227777777777000000000000066622222211112222225555555555555500005555557777111117771111177711170811118066666661
77722222222222222222277777177177007000700000000022222111111222225555555555555000000555557117711111177111111771178117711866666661
777222222222222222222777772112770070007000000666222211111111222255555555555500000000555571ddd7ddddddd7ddddddd7178117711856666651
772222222222222222222277772222770676067600077777222111111111122255555555555000000000055571dddddddddddddddddddd170811118055555551
77222222222222222222227777722777067606760000066622111111111111225555555555000000000000557111111111111111111111170081180015555551
72222222222222222222222757777775067606760000000021111111111111125555555550000000000000055777777777777777777777750008800001111110
722222222222222222222227577777777777777777777775211111111111111211111111500000000000000557777775777ddd17777ddd170077770056666650
7222222222222222222222277777777777777777777777772211111111111122111111115500000000000055777711177777dd177777dd170777677066666661
72222722222222222222222777777777777777777777777722211111111112221111111155500000000005557117711771177d1771177d177777777766666661
722222222222222222222227777777711777777117777777222211111111222211111111555500000000555571111717711dd717711dd7177777767766666661
7722222222222222222722777777771221777712217777772222211111122222111111115555500000055555711ddd17711ddd17711ddd177767777756666651
7772222222777722222227777177712222111122221777172222221111222222111111115555550000555555711ddd17711ddd17711ddd177777777755555551
7777722227777772222777777211122222222222222111272222222112222222111111115555555005555555711ddd17711ddd17711111170777677015555551
5777777777777777777777755777777777777777777777752222222222222222111111115555555555555555711ddd17711ddd17577777750077770001111110
00000000047744444944977706660000000000000000000000000000166666100066600000000000000000000000000000000000000000000000000000000000
00000007777794999944997775550000000000000000000000000008667776600618160000000000000000000000000000000000000000000000000000000000
0000077777774991194491777ddd00000aa000a0000800000000008e666666606118116000000000000000000000000000000000000000000000000000000000
0000777779949911199991774755000000a0baa0000e8000800000e861161160611888600000000000000000000000000000a000000000000000000000000000
0000777999499112222222272949000000ab0aa0000880008e000b806116116061111160000000000000000000000000000a0a00000000000000000000000000
000799999499122222222227221490000003b0b00b00b0008e000b00166666100611160000000000000000000000000000a000a0000000000000000000000000
007979994991222777722227222199000b03b0b00bb03b0b0b00b30006060600006660000000000000000000000000000a000009000000000000000000000000
0999799499122277777772222222119000bb30b0b30b3b030b0b3b000000000000000000000000000000000000000000a0000009000000000000000000000000
99999944111111117111111111111119000000000000000055b35555000000000000000000000000000000000000000900000009000a00000000000000000000
04412949122222222222222222222214000000000000000055b3555500000000000000000000000000000000000000a00000000090a0a0000000000000000000
094119491111111111111111111111140000000000000000555b35550000000000000000000000000000000000000900000000000a000a000000000000000000
0941294912222222222222222222229400000000082800005555b555000000000000000000000000000000000000090000000000000000000000000000000000
094129491222222222222222222222940000000082e800005555b55500000000000000000eeeee00eeeeee00ee009000eeeeee000eeeee00eeeeee00eeeeee00
09412949122444422222222224444294000000088e8000005553b5550000000000000000eeeeeee0eeeeeee0ee090000eeeeeee0eeeeeee0eeeeeee0eeeeeee0
094129491291411222222222914112940000000888200000555b55550000000000000000ee000ee0ee000000ee000000ee000000ee00000000ee0000ee000000
09412949129141122444422291411294000000088200000055555555000000000000000022000000222200002200000022220000222222200022000022220000
094129491291411221111422914112940000000b0000000000000000000000000000000022000220220000002200002022000000000000200022000022000000
09412949129141122122242291411294000000b00000000000000000000000000000000022222220222222002222222022222200222222200022000022222200
0941294912914112212229229141129408000b300000000000000000000000000000000002222200222222202222222022222220022222000022000022222220
0941294912914112212224229141129408800bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
094129491294444221222422944442940080033b0000000000000000000000000000000000000000000009000000000000000000000000000000900000000000
0941294912111112212224221111129400b00033b00b000000000000000000000000000000000000000090000000000000666660000000000000090000000000
09412949122277772122242222222294000b0033b0b3000000000000000000000000000000000000009900000000000006666666000000000000009000000000
094129491227777777722422277722940003b0bb30b3000000000000000000000000000000000000090000000000000000000066000000000000009000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000009000000000000dd00006666000dd00000000009000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000dd000dddd0000dd00000000009009000000
0000000000000000000000000000000000000000000000000000000000000000000000000000009000000000000000000dd00000000000000000002020900000
0000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000ddddddd000000000000000200090000
0000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000ddddddd000000000000000000020000
00000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000002000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000020
fff73f7abef790051a041219c061b4124793f142221d00382c1243a2d9283c2e1b1e08b3dbe769b8065ca69dc4f9ffa2be27c1fff7f674b3fcfff1cc5f527d9f
fb8cbeffddbf9f1678e3df3addf7df5ef9f92ffbede7aef1b5e9f17fbcf2f3dffb3f7cf1fb4097427933f792ff3f5ec7ff8938d3fcf5275f93e7bffe7cf37bc1
efffe46e78efaffefcf77cd1ef7597dff7254ecfe7fff1cff1ef71faaff5d6cf23f29b793e0f34274819919f1e78727cf02deffac58b3f83eb97c3df92f0197c
7f285e0ffb88ca9ff7cff42fce97845d578df7bffbcff62d4e722b9fff44048160306ef7462d834eff4ffba5eff587f85bb52b426fcffceff6ff7bffdd7b0294
3fffbf93dff16bb72eb8ff36683872c1c3ebfe88d2091bfdef9f72e7a6bd69f3c3e1845197f76b43bc96ef8fd7e94affb9ff1acbc27862e1e8421b11fc1e0936
1ebef1bde7b5f1f57b43c16619f0cd1b758febd0cf5981ff79ffbc3ff70cfe0540400de85651d0478ba43731182a3f3542aeddb2be1e9e57527dae393fad1fed
7e3f509bb2b3e4f30748ab07def87e79bc7cb6ef1f487297d1f35d929f1e8172f4f72ea585f7a7f99cf59f32f7df172f49dee19acb36991935610f88666714e4
2bfde9030ff50d5efbe7214f0f5445ee31078f1ffcf3ffcc2fb6c54e81e919e622709fe87424f707c79f6fc7ff2c1af3bc4e0197627193c1eb57fbd1ec21d46c
53e8c3906207d68ef4f3f1ba4c170f6efc32ef4efef2bd3997c17cefb341c5b3ef274b325e1f4fa058c1c59924294ed3c11bc4c14878723e1f3ff85e09f12a2b
dc1e1fbefd7c7f8c3bde3e112cfb84e7217f80e06f86812190809c8d6ba14ef63950bcfd4ad76f3408c5c5c7e7fbc14a997274f7197c90195e1769ba2c1ef709
d3e832d4dff0670f074fecff0276642b346bcf6f7d1e59c5ddfbbf3fa4eac61766fb6d3f5e7a10ffffff0fbe3ff72024b1f02e45541caecb37d5215e21621a60
13dd132ab65eb972169ffb1772bf4e6a4cefffb1f346bb61d9362ffff93c77c1fc17d7bc9efff3f29c37cafab6e2169b1efffc689f12bf3e9f5ea421764efffd
688cc52ff87ce0ef79b7e79be717ef4376321bf98c29ecf478c56f70196e79cf49ee12cbefa73b53fb5b62f7deac62dd21e88be96c99ebffd119429d29de9d21
968cbe9fd28763297afded569481f47f784cc27b326f80293e1e794942639b09546b8029da9a854294e859a72c3911b4e79c067ad6a45298f11dad3e95ff3f90
bf8f4c4d84294e51b461584aa58fc52b54ec1e1242f7ef7bcde411ebc27607cfaff68af9f0e8e5f3df39a5a9ec2612cd9fbd39ae80e479c7e8c46b4e70e8dfaf
b72bf3ff70ff70dff509d2f76614cebcbe80679d2f341f5629ffe57df0bf1eff17c9b195f73f888c794ef296cdbdfaff4e80f2ff0b42750c5be369ff10e16311
1919b1b9e995243f78f12ef72bcfefbc31e127cc9dc3be3d479c01ba4e0ff305390b8f94efa429f3293ff989cfee8ac5e2bf5df5b4c35b333148842fb4ec83e3
fb40bfbf9fdf8c22ffe5cf59c47741dd05bf77fef2976fc122753616dd1dc9e8e29cc55000fc9e528bc24e0ff79cff3cfd7cff5e7af9f7ec317c8ba98e3cf43b
44e9d3d72129f9cea36f7c1f8ef0170ffb932fcff622f7def8d32f872e9dc7e88adff6e8d2bffdcf5bbeff0f46fff9b710ff094ff9f10e7a369f2ff9fdf70e71
9aef726f74ef732f3b01ef0888f3f71e8c3eadefb8cff8c393fcc4d19aadf0936f77ef71ef4abfef83abf7ff735b5df3df1ff71ff78ff18cf99b6ce8cbff843f
b8f36224093d31e4bf93b2f3d197e794ef70f3ff41fc8b68bcff40ff07bf7f71d0ffffff0ff797ef788fd12f67cd3b23a9309e4a24dea229218a73b32a920bb1
9f5e86657a0b4d1cc47a2394bde6b55c6270793e8c24e9c3e03eafff31e0e064367c1c1fc8ba94e1adfec7fed3709f12f5ef8102def19f569c6ff4ae9cf3ff42
f3d69fb69ee9feb8422160c2a4198ac69cf6eacb77cf29cbb32ff9cefa7337ef494eddf4f36e0eaef9de37d1de5df5392c9803cef4b679d51903fb8b80ffaaf9
71667eefe48fbd1fb7ef70fbcf8f5ff70ff78ff1838b699f693e84f004e179c940257c294f8efcf7df2f38cfcd9f37ef706ef90a9ff588f46297eff1e8f5ef97
f78d17d3fe1ff31f787376ecdf178a5c22219cf58f37e5dd09f50b92e9c2affcf27e3f78cde7c329b3bf5b7d39c72df14eec59fb42f87af79f1fa278c59f1cf3
9d576eff2f09838c33719ef74ed0569b279ffdc6ffdd7c783eff1f36e8ce93d9f3dff3eff111b3e8a45294c2374469629f5cf6424ce80cacb19944e5f3d2f3ff
57f7286e1efa0321972b4d299701bf1aebfffc329ff696463bcff8c2ff8f3c07bf74e685e0f8f96a4390bff3d26ef75e59f528e3bf6feee3d6eff5da55efac6b
cdaca78f125a226789e17c4df52f36c5dfb4ec332fc3bdfd7e0f4eff073f14e5f0294dff629fc1d7f71eacf0ee4e86294f74492ac1ab8b0f4217df7f7ef7eaf7
e52743fff83278f5c1fff87e8722ff3bd59fd31746e8feff2adc1f44ef0ff8d1f8726702bca9e9ef2629df3f9b3fce80f3af72c195e2f3ff09ffe126f7df4b6e
8f3e840e19f9dea0d8099c12ff2f1f740ca9c9b059f73d3e29f9c3f30fbd19fd6f70bff1c46f3df7772bbef097674a8ff34446b0fb864ef72227efdb0cf1eaff
78ff7078bdea9c99cb1cf661215c2cf11ff73c31ffc04a01974e32c2fff1cef71f85f8f92dc7fc31198569da2f34e78f9e0299012505bb42cc874ea30a97ea30
2f775e0f4eff2f0d6ede12b322e83e4f39f1c5fe9f35a74f24e0bf180844e303ef887c2c068f184621ff79f4529e29ccf2cb0a9855429fd8f3832c1e721f32e3
70fff92f5621e78c178f2294619529f3eff6bd5b719cf0968f9d6cf9274e8adfcf3f198c4f20d0d7e0af45ef18f1cffd8a8b8f5e0e72fc1cf7c8971d5e87e7cc
fe4e70f34270732c2c928329322f305e19b8f3c99c91b4256ef1c7e4a2f74e8c9e866f0bf529f98b42cbee0fb1f1bc5f4c6c1ce0f3eff8e8c568f523def7fb06
ff5ef83e8f326e8ede7274e375ef2593de129348193ea7fdf1a6747fceb7cf3437864e809cf5193f94e8ffb58eef77fffbfff9af3f7be9d7dff7e79fd2f38f7e
97dbba4529acff10169ffd06bdff629f1af3effaed8cf3eb8e81f4677321e3699f9df432437b2cf96310343bdddbe7a8eea9f923bc974c55eff479fbad9c8f01
f3faffbbfffdffce83c6c3ef7387ce0736cf39f1e8f127e964eac329f3df2bfde3f622857f62f3a023f39c19b5cf59c7772bcf3c59bc2e126f3ef29f587d0f75
eb769bec9ff9cfce7c87f1956eff0269ffc99b8c3785f7ceff58bdf6725fddec92eff0bf3293d15c4cfdffffff0f3d3ff7805408797959d6dd71d9a482a49403
690e62fa40dbe54efff966e75b8efff3dd15f3769fff7ad7eafcf90dfffb393dffa9fff7fed76e6f36e70fff71339df1fbcf3b1f3df9ebff5bfb0ffbbd7fbd5b
df7e8f39ff181e7def27ff832f34e2fb7ef43f3dff325fb08fb21fe1fcf0ae6f3cf1bf1ebcb8cf7293dde0cf3cf3cf29bcf1ccf2fff37f8ffd90eff28086e757
b0ef66bf7efdcff327833f3b62e7edef5cf0529bdff485ff6fb3072efffb0e8fc21e7cf7cf23ef3f7e6f32fff79233f3cf3948ff1cfc19fff7442898f5cf927d
e7a0ffffe2f6ef2e7420ffffff0f3d3ff700877e95aa59d6947b484285e1bf7589a9f2a01413ef13cf198fff72d88ba31752efb5befff84e0ffbfe37d7efff71
fff7ad98ffd4e5fffff67ff0f70effffb069f5ef9ff35edb9c79affb48ffd12f39b30f7df9cf49fcf098ff758fbc3f37b7df6b394ef3f38f1ffbcf9ef7c1ef5f
b2fcb365eff04887f5e7eccfc121e0fcf0e73ef59fd6fff8ddffd61ffe72f37f9f5e9cfa93c1c3e9467a473f0f3fff66efefd71ff38f887e2ef0efcc727d1107
7cfa788df0faffb4ee7f7a4278cffff0788ef69f3df0899ffff104e7574ed7ce986ef03e78c3ef3f3cfbcffb78ff768fff38ffffff0f3d3ff200682e34e807c2
79fe7e632c2c6b355cfef75429def84dfff3e4b1dfffff107c1cffff7087efffd78767c5f5c9fff702cfff98442feef7f97f6cffa9b462fff702e78f72f78ff7
177872fb8fffa7ec4dffd3c1ef80fff84c31e7bc10ffb8c1ef6e81eff190490776e0efffb868ff7a58ff34aef8cf3ef713cf797cf59f9c74379ff79fb29fd2b4
dff5257a33cf4efbb7f3a77cf09fcfa9f3f6eef13f8f56f8f5facbc0ff71e71758f3bface74fbef56fff7168fffffd10f3dfff98bef72001cbe310d1a4592261
d8119484401cd90423bddca0b815ba4e2b9ef7b1ef0970c333206140cfd483839fffff8a5be5ac9e832f4ea42748f5d59c323f9b2d029cecc79f7a8cf11eff1c
f4cfffffb6fc7fedf0e70ef87b2bf58f78d3bde7acefafde49f36796c3c9f9ff2238f1f1d4ff4fbe4ecf7f9cfcf737c1efcbebf3fafb73e7b3f8f3f9f3f54e43
807b5c9fb42f7cd9c8853bfaf35af8af58ce7fff1481f7560f59ff3cff2c1846f421932eff170721000000000000000000000000000000000000000000000000
__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
70000000000000000000000000000000000000000000000000000007770000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
7000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000007
700000000000000000000000000000000000000070000000000000000000000a0a00000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000a000a0000000000000000000000000000000000000000000000000000000000007
7000000000000000000000000000000000000000000000000000000000000a000009000000000000000000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000000000000000000000a0000009000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000900000009000a00000000000000000000000000000000000000000000000000000007
7000000000000000000000000000000000000000000000000000000000a00000000090a0a0000000000000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000000000000000000900000000000a000a000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000090000700000000000000000000000000000000000000000000000000000000000000007
7000000000000000000000000000000000000eeeee00eeeeee00ee009000e777ee000eeeee00eeeeee00eeeeee00000000000000000000000000000000000007
700000000000000000000000000000000000eeeeeee0eeeeeee0ee090000ee7eeee0eeeeeee0eeeeeee0eeeeeee0000000000000000000000000000000000007
700000000000000000000000000000000000ee000ee0ee000000ee000000ee000000ee00000000ee0000ee000000000000000000000000000000000000000007
70000000000000000000000000000000000022000000222200002200000022220000222222200022000022220000000000000000000000000000000000000007
70000000000000000000000000000000000022000220220000002200002022000000000000200022000022000000000000000000000000000000000000000007
70000000000000000000000000000000000022222220222222002222222022222200222222200022000022222200000000000000000000000007000000000007
70000000000000000000000000000000000002222200222222202722222022222220022222000022000022222220000000000000000000000077700000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000000007
70000000000000000000000000000000000000000000000009000000000000000000000000000000900000000000000000000000000000000777000000000007
70000000000000000000000000000000000000000000000090000000000000666660000000000000090000000000000000000000000000000070000000000007
70000000000000000000000000000000000000000000009900000000000006666666000000000000009000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000090000000000000000000066000000000000009000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000009000000000000dd00006666000dd00000000009000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000020000000000000dd000dddd0000dd00000000009009000000000000000000000000000000000000000007
7000000000000000000000000000000000000000009000000000000000000dd00000000000000000002020900000000000000000000000000000000000000007
7000000000000000000000000000000000000000020000000000000000000ddddddd000000000000000200090000000000000000000000000000000000000007
7000000000000000000000000000000000000000020000000000000000000ddddddd000000000000000000020000000000000000000000000000000000000007
70000000000000000000000000000000000000000200000000000000000000000000000070000000000000002000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000020000000000000000000000000000000000000000000000000020000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000e0000000000000000e0000000000eee0000000000000000000000000000000000000000000000000000007
700000000000000000000000000000000000000000e0000ee0ee00eee0e0000ee000000e00ee00eee0e0e0000000000000000000000000000000000000000007
700000000000000000000000000000000000000000e000e0e0e0e00e000000e00000000e00e0e0ee00ee00000000000000000000000000000000000000000007
700000000000000000000000000000000000000000e000eee0e0e00e00000000e000000e00ee00e000e0e0000000000000000000000000000000000000000007
700000000000000000000000000000000000000000eee0e0e0e0e0eee00000ee0000000e00e0e00ee0e0e0000000000000000000000000000000000000000007
70000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000777001110000001101110111011100000111010100000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000070001010000010001010111010000000101010100000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000001110000010001110101011000000110011100000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000001010000010101010101010000000101000100000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000001010000011101010101011100000111011100000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007
70000000000000000000000000000000000000555055505500550050500000555050500550555005500550550000000000000000000070000000000000000007
70000000000000000000000000000000000000555050505050505050500000050050505050505050005050505000000000000000000777000000000000000007
70000000000000000000000000000000000000505055505050505055500000050055505050550055505050505000000000000000000070000000000000000007
70000000000000000000000000000000000000505050505050505000500000050050505050505000505050505000000000000000000000000000000000000007
70000000000000000000000000000000070000505050505550555055500000050050505500505055005500505000000007000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000070000000000007
70000000000000000000000000000000000000000000550005505550500000005550555055505550505000000000000000000000000000000777000000000007
70000000000000000000000000000000000000000000505050505000500000005050500050505050505000000000000000000000000000000070000000000007
70000000000000000000000000000000000000000000505050505500500000005500550055005500555000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000505050505000500000005050500050505050005000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000505055005550555000005550555050505050555000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000500055505500555000005550555055505500555000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000500050005050505000005050505005005050500000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000500055005050555000005500555005005050550000000000000000000000000000007000000000007007
70000000000000000000000000000000000000000000500050005050505000005050505005005050500000000000000000000000000000000000000000077707
70000000000000000000000000000000000000000000555055505050505000005050505055505050555000000000000000000000000000000000000000007007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777

__gff__
0003000000000101010101000000000083838300000001010101010000000001838383830800838381818107070700038383838383838383818181070707000001010101010101000000000000000000010101010101810000000000000000000101010101010100000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01030306245342452024510245102451024510245002450030500305002b5002b5002950029500245002450030500305002b5002b5002950029500245002450030500305002b5002b50029500295002450024500
0104020317770187711877018770154001540015400164001740018400194001a4001b4001d4001e4001f4001f4001f4001c40018400164000000000000000000000000000000000000000000000000000000000
010b05080017000160001500014000132001220012200122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010605081817300154001400013000122001220012200122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002f6702f6302f6202f6202f6102f6102f6102f6102f6152f61500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400021837020370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040002183701f370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000c6400c070110611305130634306250c06000051244502b4513a4503a4502b0241f021320213202329040290502a0612a0602c0612c0600c65400000186631e0601f0511f0501e0411d0311c02100000
010700000c05318653246440061200612000000000000000301532b1402e13035130241342b1242e1143511500673186230c621006150065324620186212461524340246433233131321303112b3110000000000
010b000030830308252b8202b8152982029815248202481530820308152b8202b8152982029815248202481530820308152b8102b8152981029815248102481530820308152b8102b81529810298152481024815
010b0000080400802513045130251a0451a0251f0451f025080400802513045130251a0451a0251f0451f025080400802513045130251a0451a0251f0451f025080400802513045130251a0451a0251f0451f025
010b00000c0400c02513045130251a0451a0251f0451f0250c0400c02513045130251a0451a0251f0451f0250c0400c02513045130251a0451a0251f0451f0250c0400c02513045130251a0451a0251f0451f025
010b00000a0400a02513045130251a0451a0251f0451f0250a0400a02513045130251a0451a0251f0451f0250a0400a02513045130251a0451a0251f0451f0250a0400a02513045130251a0451a0251f0451f025
010b0000060400602513045130251a0451a0251f0451f025060400602513045130251a0451a0251f0451f025070400702513045130251a0451a0251f0451f025070400702513045130251a0451a0251f0451f025
01040000306532405330653306103061018615376003760000654000003065424800248002480000000000003c6240c6412466113075260741a0610e0510206425041190310d04424031180210c024180110c011
010b0000247402473500000000002b7402b73500000000002b7402b73500000000002b7402b73500000240002b9402b7302b7222b7122c740007002e7402e7302e7202e71530750000002e7402e7352c7402c735
010b00002b9402b7302b7302b7222b7122b7122c7402b740297402973029730297202971029712297120000027740277302773027720277122771229740277402674026730267202671226712267120000000000
010c000013033006001f033210313c02100654070140c0213e0143d0213c0213a0213b0213a0213901138011370113601135011340113301132011300111f02100614006110c62118631246310c6210061100615
010b0000247402473024722247152b7402b73500000000002b7402b73500000000002b7402b73500000000002b7402b7302b7222b7152c740000002e9402e7302e7422e73530740307352e7402e7352c7402c735
010b0000090400902513040130251a0401a0251f0401f0250804008025120401202519040190251e0401e0250704007025110401102518040180251d0401d0250604006025140401402518040180251d0401d025
010b00002b9402b7302b7302b7222b7122b7122c7402b7302974029730297302972229712297122b7402973027740277302772027722277122771229740277302674026730267302672226712267122671026710
010b000014b5014a2014a2014a5014a2014a2014a5014a2014a5014a2014a2014a5014a2014a2014b5020a2014b5014a2014a2014a5014a2014a2014a5014a2014a5014a2014a2014a5014a2014a2016a5016a20
010600002463424160188352b1501f825301402481524140188252b1301f815301202481524130188152b1201f815301102481524120188151f8101f81524810248150000018c0018c0000000000000000000000
010b000018b5018a2018a2018a5018a2018a2018a5018a2018a5018a2018a2018a5018a2018a2018b5024a2018b5018a2018a2018a5018a2018a2018a5018a2018a5018a2018a2018a5018a2018a201aa5018a20
010b000016b5016a2016a2016a5016a2016a2016a5016a2016a5016a2016a2016a5016a2016a2016b5022a2016b5016a2016a2016a5016a2016a2016a5016a2016a5016a2016a2016a5016a2016a2018a5016a20
010b000012b5012a2012a2012a5012a2012a2012a5012a2012b5012a2012a2012a5012a2012a201ea501ea2007b50000000000000000000000000007b50000000000000000000000000018c4018c1024a3018a21
010b000014b5014a2014a2014a5014a2014a2014a5014a2014c4014c1014a2014a5014a2014a2014b5020a2014b5014a2014a2014a5014a2014a2014a5014a2014c4014c1014a2014a5014a2014a2016a5016a20
010b000018b5018a2018a2018a5018a2018a2018a5018a2018c4018c1018a2018a5018a2018a2018b5024a2018b5018a2018a2018a5018a2018a2018a5018a2018c4018c1018a2018a5018a2018a201ac3018a20
010b000016b5016a2016a2016a5016a2016a2016a5016a2016c4016c1016a2016a5016a2016a2016b5022a2016b5016a2016a2016a5016a2016a2016a5016a2016c4016c1016a2016a5016a2016a2018a5016a20
010b00000000030810308152b8102b8152981029815248102481530810308152b8102b8152981029815248102481530810308152b8102b8152981029815248102481530810308152b8102b815298102981524810
010b000022130221202211222112291302912500000000002912029115000000000029110291150000000000291302912527135001002912500100291302b1302b1202b112291302912527135001002612500000
010b0000241302412024112241122b1302b12500100001002b1202b11500100001002b1102b11500100001002b1302b12529135001002b125001002b1302c1302c1202c1122b1302b12529135001002712500000
010b0000050400502513045130251a0451a0251f0451f025050400502513045130251a0451a0251f0451f025050400502513045130251a0451a0251f0451f025050400502513045130251a0451a0251f0451f025
010b000011b5011a2011a2011a5011a2011a2011a5011a2011c4011c1011a2011a5011a2011a2011b501da2011b5011a2011a2011a5011a2011a2011a5011a2011c4011c1011a2011a5011a2011a2011a5013a20
010b000026130261202611226112291302912500000000002912029115000000000029110291150000000000291302912527135001002912500100291302b1302b1202b112291302912527135001002612500000
010b0000241302412024112241122b1302b12500100001002b1202b11500100001002b1102b11500100001002b1102b11529100001002b1102b1152b1002c1002b1102b1152b1002b1002b1102c1112e7212f731
010b00000b0400b02513045130251a0451a0251f0451f0250b0400b02513045130251a0451a0251f0451f0252b0242b01500000000002b0242b01500000000002b0342b02500000000002b0442b0352b00000000
010b000017b5017a2017a2017a5017a2017a2017a5017a2017c4017c1017a2017a5017a2017a2017b5023a2013b5013a4013a4213a3207a2107a1207a1207a120000000000000000000018b5018a4016b5016a40
010b0000307503074500000000003075030745000000000030750307450000000000307503074030732307253275032740327323272533755000003295032740327323272530750000002e7502e7453074500000
010b00003275032745000000000032740327350000000000327403273032722327153375033745357303572533950337403373033722337123371532950327303273232742337503274030750307403073230725
010b00002c7502c7402c7322c7322c7222c7222e7502e7402e7322e7222e7122e715307503074030732307422f7502f7402f7322f7322f7222f72230750307403073230722307123071532750327403273232725
010b00002a7502b7412b7402b7302b7322b7222b7222b7122b7122b7122b7122b715297402b7302c7302b7502b7402b7402b7322b7222b7122b7122b7150000000000000000000000000297002b7002c7002b700
010b00002f7502f7402f7402f7322f7322f7423075030740307403073230732307423275032740327323273533750337403373033722337123371235750337403275032740327303272232722327123271232715
010b0000083550000013d200000013d1000000083550000013d200000013d1000000083550000013d20000000a3550000013e200000013e10000000a3550000013e200000013e10000000a3550000013e2000000
010b00000b3550000013e200000013e10000000b3550000013e200000013e10000000b3550000013e20000000c340133251b3150c340133251b3150a340133251b3150a340133251b3150a340133201b3121b315
010b0000083550000013d200000013d1000000083550000013d200000013d1000000083550000013d2000000073550000013e2000e0013e1000000073550000013e200000013e1000000073550000013e2000000
010b0000063550000013e200000013e1000000063550000013e200000013e1000000063550000013e2000000073550000013e2000e0013e1000000073550000013e200000013e1000000073550000013e2000000
010b000014b5014a4014a3014a5014c4014a4014b4014a3014b5014a5014a4014a3014c4014a3020a350000016b5016a500000016b5016c400000016b5016a4016a3016a2216a2216a1216c4016a5016b5022a40
010b000017b5017a4017a3017a5017c4017a4017b4017a3017b5017a5017a4017a3013c4013a301fa350000018b5018a500000018b5018c400000016b5016a4016a3016a2216a2216a1216c4016a5018b5022a40
010b000014b5014a4014a3014a5014c4014a4014b4014a3014b5014a5014a4014a3014c4014a3020a350000013b5013a500000013b5013c400000013b5013a4013a3013a2213a2213a1213c4013a5013b501fa40
010b000012b501ea4012a3012a5012c4012a4012b4012a3012b5012a501ea4012a3012c4012a3012a350000013b501fa50000001fb5013c400000013b501fa401fa301fa221fa221fa1213c401fa5013b502ba40
018200200c60018600186140c6110c6150000000000000000c6140c61500000000000000000000246140c6110c615000000000000000000001861400611006150000000000000000c6140c615000000000000000
01820000000000ca740ca700ca700ca75000000000000000000000ca740ca700ca700ca750000000000000000000000a7400a7000a7000a750000000000000000000000000000000ca740ca7100a7100a7500000
0182002004614006111d611026111061109611056120461200611116110261110611096110561204612006111d611026112861109611056120461200611116110261110611096110561204612006120561202615
010b0000188401f850248601f850248602687024840268502886226870288502b8603087130872248002680030820268002880030810308003080030814000003080000000000000000000000000000000000000
010700000c00018600246000060000600246002b8003780037800378003780037800000000000000000000000c0001860024600006000c05318653246440061200612246532b8743787137862378523784237824
010e000018a1418a1018a2018a3018a4018a5018a6018a7018a6218a5218a4218a3218a2218a1218a1218a1518a5018a4018a3018a3518a2418a4018a3018a3518a5018a4018a3018a3518a2418a4018a3018a35
010e00000c0431a8001c80018800000001f8000c0330c0230c033268002480026800288002680028800298000c7500c74513750137451a7501a74518750187451f7501f745247402473526740267352474024735
011000002b7402b73530740307353274032730327203271032710327103271032715000000000000000000001f8502b8522b8422b835000000000000000000000000000000000000000000000000000000000000
010e00000cc400cc45130001a000130001a0000cc450cc450cc430cc4500000000000cc400cc4500000000000cc400cc45000000000000000000000000000000130161a026130361a046130361a026130161a016
01100000130161a026180361f046130461a036180261f016130161a016180161f015130001a000130001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000018a1418a1018a2018a3018a4018a5018a6018a7018a6218a5218a4218a3218a2218a1218a1218a1500000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000180161f026180361f046180361f026180161f016180161f016180161f0150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00000000000000000000000000000000000000000000006140c6110c611186111861124611246113062130621246112461118611186110c61100611006150000000000000000000000000000000000000000
__music__
00 091d4344
00 091d5656
01 090a1555
00 090b1757
00 090c1858
00 090d194e
00 1a0a0f51
00 1b0b1057
00 1c0c1258
00 56131444
00 21201e44
00 1b0b1f44
00 1c0c2244
00 25242344
00 2f2b2644
00 302c2744
00 312d2844
00 322e2944
00 2f2b2644
00 302c2744
00 312d2844
02 322e2a44
00 091d4344
00 091d4344
01 090a4344
00 090b4344
00 090c4344
00 090d4e44
00 090a4f44
00 090b5044
00 090c5244
00 09135444
00 09201d44
00 090b1d44
00 090c1d44
02 090d1d44
03 33347544
03 73343544
03 41423544
00 36374344
00 38393b3f
04 3d3a3c3e

