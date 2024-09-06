<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="props_small" tilewidth="32" tileheight="32" tilecount="28" columns="7">
 <image source="../images/props_small.png" width="224" height="128"/>
 <tile id="0" type="score_bonus">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="16"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="20"/>
  </properties>
 </tile>
 <tile id="1" type="score_bonus_small">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="14"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="8"/>
  </properties>
 </tile>
 <tile id="2" type="grenades">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="16"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="15"/>
  </properties>
 </tile>
 <tile id="3" type="tank_ammo">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="14"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="15"/>
  </properties>
 </tile>
 <tile id="4" type="tank_repair">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="15"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="5" type="health">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="7" type="assault_rifle">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="11"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="19"/>
  </properties>
 </tile>
 <tile id="8" type="bazooka">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="20"/>
  </properties>
 </tile>
 <tile id="9" type="flame_thrower">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="15"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="29"/>
  </properties>
 </tile>
 <tile id="10" type="machine_gun">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="22"/>
  </properties>
 </tile>
 <tile id="11" type="smg">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="12" type="shotgun">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="9"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="19"/>
  </properties>
 </tile>
 <tile id="14" type="barrel">
  <properties>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="25"/>
   <property name="hits" type="int" value="1"/>
   <property name="smoke_when_hit" type="bool" value="true"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="15" type="barrel_explosive">
  <properties>
   <property name="destructible" type="bool" value="true"/>
   <property name="explosive" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="25"/>
   <property name="hits" type="int" value="2"/>
   <property name="smoke_when_hit" type="bool" value="true"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="16" type="box">
  <properties>
   <property name="burns" type="bool" value="true"/>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="26"/>
   <property name="hits" type="int" value="1"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="17" type="box_small">
  <properties>
   <property name="burns" type="bool" value="true"/>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="22"/>
   <property name="hits" type="int" value="1"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="18" type="score_container">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="21"/>
   <property name="hits" type="int" value="2"/>
   <property name="spawn_score" type="int" value="1000"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="19" type="metal_box">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="26"/>
   <property name="hits" type="int" value="3"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="20" type="metal_box_small">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="22"/>
   <property name="hits" type="int" value="3"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="25" type="land_mine">
  <properties>
   <property name="explode_on_contact" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="spawn_when_close" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="26" type="land_mine">
  <properties>
   <property name="explode_on_contact" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="spawn_when_close" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="27" type="bush_small">
  <properties>
   <property name="grenade_hits" type="int" value="1"/>
   <property name="height" type="int" value="20"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
</tileset>
