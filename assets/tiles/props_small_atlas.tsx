<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="props_small_atlas" tilewidth="32" tileheight="32" tilecount="768" columns="24">
 <image source="../images/tileset.png" width="768" height="1024"/>
 <tile id="384" type="score_1000">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="16"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="20"/>
  </properties>
 </tile>
 <tile id="385" type="score_500">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="14"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="8"/>
  </properties>
 </tile>
 <tile id="386" type="grenades">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="16"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="15"/>
  </properties>
 </tile>
 <tile id="387" type="tank_ammo">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="14"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="15"/>
  </properties>
 </tile>
 <tile id="388" type="tank_repair">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="15"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="389" type="health">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="408" type="assault_rifle">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="11"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="19"/>
  </properties>
 </tile>
 <tile id="409" type="bazooka">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="20"/>
  </properties>
 </tile>
 <tile id="410" type="flame_thrower">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="15"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="29"/>
  </properties>
 </tile>
 <tile id="411" type="machine_gun">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="22"/>
  </properties>
 </tile>
 <tile id="412" type="smg">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="13"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
 <tile id="413" type="shotgun">
  <properties>
   <property name="consumable" type="bool" value="true"/>
   <property name="height" type="int" value="9"/>
   <property name="spawned" type="bool" value="true"/>
   <property name="width" type="int" value="19"/>
  </properties>
 </tile>
 <tile id="432" type="barrel">
  <properties>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="12"/>
   <property name="hits" type="int" value="16"/>
   <property name="metal" type="bool" value="true"/>
   <property name="smoke_when_hit" type="bool" value="true"/>
   <property name="visual_height" type="int" value="25"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="433" type="barrel">
  <properties>
   <property name="destructible" type="bool" value="true"/>
   <property name="explosive" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="12"/>
   <property name="hits" type="int" value="8"/>
   <property name="metal" type="bool" value="true"/>
   <property name="smoke_when_hit" type="bool" value="true"/>
   <property name="visual_height" type="int" value="25"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="434" type="box">
  <properties>
   <property name="burns" type="bool" value="true"/>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="12"/>
   <property name="hits" type="int" value="1"/>
   <property name="visual_height" type="int" value="25"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="435" type="box">
  <properties>
   <property name="burns" type="bool" value="true"/>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="flammable" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="hits" type="int" value="1"/>
   <property name="visual_height" type="int" value="20"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="436" type="score_500">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="hits" type="int" value="2"/>
   <property name="spawn_score" type="int" value="1000"/>
   <property name="visual_height" type="int" value="20"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="437" type="container">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="12"/>
   <property name="hits" type="int" value="3"/>
   <property name="metal" type="bool" value="true"/>
   <property name="visual_height" type="int" value="25"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="438" type="container">
  <properties>
   <property name="crack_when_hit" type="bool" value="true"/>
   <property name="destructible" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="hits" type="int" value="3"/>
   <property name="metal" type="bool" value="true"/>
   <property name="visual_height" type="int" value="20"/>
   <property name="width" type="int" value="14"/>
  </properties>
 </tile>
 <tile id="460" type="mine">
  <properties>
   <property name="explode_on_contact" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="spawn_when_close" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="461" type="mine">
  <properties>
   <property name="explode_on_contact" type="bool" value="true"/>
   <property name="height" type="int" value="10"/>
   <property name="spawn_when_close" type="bool" value="true"/>
   <property name="width" type="int" value="12"/>
  </properties>
 </tile>
 <tile id="462" type="bush">
  <properties>
   <property name="grenade_hits" type="int" value="1"/>
   <property name="height" type="int" value="16"/>
   <property name="visual_height" type="int" value="20"/>
   <property name="width" type="int" value="16"/>
  </properties>
 </tile>
</tileset>
