globals
[
  grid-x-inc               ;; the amount of patches between two roads in the x direction
  grid-y-inc               ;; the amount of patches between two roads in the y direction
  acceleration             ;; the constant that controls how much a car speeds up or slows down by if
  ;; patch agentsets
  intersections ;; agentset containing the patches that are intersections
  roads         ;; agentset containing the patches that are roads

  carsA
  carsB

  sn
  ns
  ew
  we

  local-flow-list
  global-flow-list
  global-speed-list
  global-density
  global-patches-traveled-list

  residential_area ;;patch
  work_area ;;patch

]
patches-own
[


  direction ;; the direction of the street
  intersection?   ;; true if the patch is at the intersection of two roads

  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.

                  ;; false for non-intersection patches.
  cars-over
  chemical
  average-chemical
]

turtles-own
[
  speed     ;; the speed of the turtle
  speed-min
  up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  work      ;; the patch where they work
  house     ;; the patch where they live
  goal      ;; where am I currently headed
  patches-traveled
  use_chemical?
]

to setup
  clear-all
  setup-globals
  setup-patches
  set-default-shape turtles "square"

  ;set-default-shape turtles "car"
  create-turtles num-cars [
    setup-cars
  ]
  let p num-cars * cars_afected
  ;;show p
  ask (n-of p turtles) [
    set use_chemical? true
  ]
  setup-headings
  setup-color-turtles
  set global-density (count turtles / count patches with[pcolor != 38])
  reset-ticks
end
to setup-cars  ;; turtle procedure
  set speed-min 0
  set patches-traveled 0
  ;let goal-candidates patches with [intersection? = true]; and occuped? = false]
  let goal-candidates [patches in-radius 20 with[intersection?]] of patch 23 -22
  set house one-of goal-candidates;patch -23 24 ;
  ;set goal-candidates patches with [intersection? = true]; and occuped? = false]
  set goal-candidates [patches in-radius 20 with[intersection?]] of patch -23 24
  ;; choose at random a location for work, make sure work is not located at same location as house
  set work one-of goal-candidates;patch 23 -22;
  set goal work
  put-on-empty-road
  ifelse intersection? [
    ifelse random 2 = 0
      [ set up-car? true ]
      [ set up-car? false ]
  ]
  [ ; if the turtle is on a vertical road (rather than a horizontal one)
    ifelse (floor ((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
      [ set up-car? true ]
      [ set up-car? false ]
  ]
  ifelse up-car?
    [ set heading 180 ]
    [ set heading 90 ]

  set use_chemical? false
end

to update-plot

  set-current-plot "Viajes realizados"
  set-current-plot-pen "plot"
  set-plot-pen-color black
  if not empty? global-patches-traveled-list[
    plotxy ticks length global-patches-traveled-list
  ]

  set-current-plot "Velocidad Vs Densidad"
  set-current-plot-pen "punto"
  set-plot-pen-color red
  set-plot-pen-mode 2

  let road_section (get-section -53 -37 -24 -37) with [pcolor != 38]
  let local-density ((count turtles-on road_section) / (count road_section))

  if any? turtles-on road_section[
    let local-speed mean [speed] of turtles-on road_section
    plotxy local-speed local-density
  ]
  set-current-plot "Velocidad"
  set-current-plot-pen "p/t"
  set-plot-pen-color black
  let global-speed mean [speed] of turtles
  plotxy ticks global-speed

  create-temporary-plot-pen "mean"
  set-current-plot-pen "mean"
  set-plot-pen-color blue
  set global-speed-list fput global-speed global-speed-list
  plotxy ticks mean global-speed-list


  if ticks mod 5 = 0 [

     if  any? turtles-on road_section[
       set-current-plot "Densidad local"  ;; Density
       set-current-plot-pen "plot"
       set-plot-pen-color black
       plotxy ticks local-density


       set-current-plot "Velocidad local"  ;; Density * speed
       set-current-plot-pen "plot"
       set-plot-pen-color black
       let local-speed mean [speed] of turtles-on road_section
       plotxy ticks local-speed

       set-current-plot "Flujo local"  ;; Density * speed
       set-current-plot-pen "real"
       set-plot-pen-color red
       let local-flow (local-speed * local-density)
       plotxy ticks local-flow

       set-current-plot-pen "medio"
       set-plot-pen-color blue
       set local-flow-list fput local-flow local-flow-list
       plotxy ticks mean local-flow-list


       ;Densidad Vs Flujo
       set-current-plot "Densidad Vs Flujo"
       set-current-plot-pen "plot"
       set-plot-pen-color red
       set-plot-pen-mode 2
       plotxy local-density local-flow



       ;;Flujo Vs Velocidad
       set-current-plot "Flujo Vs Velocidad"
       set-current-plot-pen "plot"
       set-plot-pen-color red
       set-plot-pen-mode 2
       ;densidad plotxy ticks ((count turtles-on get-section -5 -9 10 5) / (count ((get-section -5 -9 10 5) with [pcolor != 38])))
       ;plotxy count carsC speed_mean
       plotxy local-flow local-speed

       ;;Flujo global
       set-current-plot "Flujo global"
       set-current-plot-pen "plot"
       set-plot-pen-color red
       let flow global-speed * global-density
       plotxy ticks flow

       set global-flow-list fput flow global-flow-list
       set-current-plot-pen "mean"
       set-plot-pen-color blue
       plotxy ticks mean global-flow-list
     ]
     ;set carsB carsA
  ]

end



to go;; turtle procedure

  update-plot
  ask turtles [
    let next next-patch
    ifelse next != nobody[
      face next
    ][
      show who
      stop
    ]

    ;rule 1
    speed-up-car
    ;rule 2 stopping, if returns -1 there is not car in front, otherwise, reduce speed
    if check-next-patch speed > -1 [
      set speed check-next-patch speed
    ]
    ;rule 2.1 stopping car, if there is an intersection, it reduces its velocity but with num of cell - 1 (to avoid 0 speed, and keep it on 1)
    if check-next-intersection speed > -1 [
      set speed check-next-intersection speed
    ]
    ;rule 2.2 , check if patch ahead is intersection and if it's empty, add 1 to speed
    if [intersection?] of patch-ahead 1 and not any? turtles-on patch-ahead 1[
      set speed speed + 1
    ]
    ;rule 3 random desaceleration
    random-speed-down
    ;rule 4
    fd speed

    set patches-traveled patches-traveled + speed

    set chemical chemical - chemical-decrement
    if chemical < 0[
      set chemical 0
    ]
  ]
  ask patches[
    set chemical chemical + chemical-increment
    if chemical > max-chemical[
      set chemical max-chemical
    ]
  ]

  tick
end

to-report check-next-intersection[howfar]
  let counter 0
  while [counter < howfar]
  [
    set counter counter + 1
    if [intersection?] of patch-ahead counter[
      report counter - 1
    ]
  ]
  report -1
end
to-report check-next-patch[howfar]
  let counter 0
  while [counter < howfar]
  [
    set counter counter + 1
    if any? turtles-on patch-ahead counter[
      report counter - 1
    ]
  ]
  report -1
end

to random-speed-down;; turtle procedure
  if random 100 < (reduce-speed-p * 100)[
    if speed >= 1[
      speed-down-car 1
    ]
  ]
end

to speed-down-car[num-patches-in-front];; turtle procedure
  set speed speed - num-patches-in-front
  if speed < speed-min [set speed speed-min]
end

to speed-up-car ;; turtle procedure
  set speed speed + 1
  if speed > speed_limit[set speed speed_limit]
end



to up-speed[ next ];; turtle procedure
  if not any? turtles-on next[
    set speed speed + 1
  ]
  if speed > speed_limit [
    set speed speed_limit
  ]
  if speed < speed_limit[
    set speed 0
  ]
end




to put-on-empty-road  ;; turtle procedure
  ;move-to one-of roads with [ not any? turtles-on self]
  move-to one-of roads with [ not any? turtles-on self and intersection? = False]

end


to setup-globals
  set sn 0
  set ns 180
  set ew 270
  set we 90
  set grid-x-inc world-width / grid-size-x
  set grid-y-inc world-height / grid-size-y
  set acceleration 0.099

  set carsA nobody
  set carsB nobody

  set local-flow-list []
  set global-flow-list []
  set global-speed-list []
  set global-patches-traveled-list []


end

to setup-patches
  ;; initialize the patch-owned variables and color the patches to a base-color
  ask patches
  [
    set cars-over nobody
    set intersection? false
    set my-row -1
    set my-column -1
    set pcolor brown + 3
    set my-row floor ((pycor + max-pycor) / grid-y-inc)
    set my-column floor ((pxcor + max-pxcor) / grid-x-inc)
    set chemical max-chemical
  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]


  ;; initialize this roads with north-south direction
  ask patches with[(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)][
    set direction ns
  ]
  ;; initialize all roads with weast-east direction
  ask patches with[(floor((pycor + max-pycor) mod grid-y-inc) = 0)][
    set direction we
  ];
  ;; creating intersections
  set intersections roads with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]
  ask roads [
    set pcolor white
  ]

  ask patches with[(floor((pxcor + max-pxcor - floor((grid-x-inc ) - 1)) mod (grid-x-inc * 2)) = 0) ][
    set direction sn ;;up
    set pcolor green;
  ]
  ask patches with[(floor((pycor + max-pycor) mod (grid-y-inc * 2 ) ) = 0)][
    set direction ew ;left
    set pcolor green;
  ]
  setup-intersections
  ;setup-roads

end
to setup-color-turtles
  ask turtles [
    let color_ random 100
    set color color_
    if use_chemical?[
      set color red
    ]
    ;set color blue
    ;ask house [set pcolor color_]
    ;ask work [set pcolor color_]
  ]
end
to setup-headings
  ask turtles-on patches with[direction = ns][set heading ns]
  ask turtles-on patches with[direction = sn][set heading sn]
  ask turtles-on patches with[direction = ew][set heading ew]
  ask turtles-on patches with[direction = we][set heading we]
end

to setup-intersections
  ask intersections
  [
    set intersection? true
    set my-row floor((pycor + max-pycor) / grid-y-inc)
    set my-column floor((pxcor + max-pxcor) / grid-x-inc)
    ;set-signal-colors
    set direction -1
  ]
end
to-report next-patch;; turtle procedure

  if goal = house and (member? patch-here [ neighbors4 ] of house) [
    set goal work
    set global-patches-traveled-list fput patches-traveled global-patches-traveled-list
    set patches-traveled 0
  ]
  ;; if I am going to work and I am next to the patch that is my work
  ;; my goal gets set to the patch that is my home
  if goal = work and (member? patch-here [ neighbors4 ] of work) [
     set goal house
     set global-patches-traveled-list fput patches-traveled global-patches-traveled-list
     set patches-traveled 0
  ]
  ;; CHOICES is an agentset of the candidate patches that the car can
  ;; move to (white patches are roads, green and red patches are lights)
  ;let choices neighbors with [ pcolor = white ];or pcolor = red or pcolor = green ]

  let orientation round(heading) mod 360
  let patch-right (right-patch 1)
  let patch-left (left-patch 1 )


  let choices neighbors4 with[self = [right-patch 1] of myself or self = [left-patch 1] of myself or self = [patch-ahead 1] of myself and (pcolor != 38)]
  ;ask choices[set pcolor red]
  ifelse orientation = we [
    ifelse [direction] of left-patch 1 = ns[
      set choices choices with [self != patch-left] ;; remove the left patch from the choices
    ][
      set choices choices with [self != patch-right] ;; otherwise remove the right patch
    ]
  ][
    ifelse orientation = sn[
      ifelse [direction] of left-patch 1 = we[
        set choices choices with [self != patch-left] ;; remove the left patch from the choices
      ][
        set choices choices with [self != patch-right] ;; otherwise remove the right patch
      ]
    ][
      ifelse orientation = ns[
        ifelse [direction] of left-patch 1 = ew[
          set choices choices with [self != patch-left] ;; remove the left patch from the choices
        ][
          set choices choices with [self != patch-right] ;; otherwise remove the right patch

        ]
      ][
        ifelse [direction] of left-patch 1 = sn[
          set choices choices with [self != patch-left] ;; remove the left patch from the choices
        ][
          set choices choices with [self != patch-right] ;; otherwise remove the right patch
        ]
      ]
    ]
  ]
  ;; choose the patch closest to the goal, this is the patch the car will move to
  let choice nobody
  ifelse [intersection?] of patch-here[
    create-chemical-left
    create-chemical-ahead
    create-chemical-right
    ifelse use_chemical?[
      set choice min-one-of choices [ distance [ goal ] of myself * ( 1 / (average-chemical + 1))]
    ][
      set choice min-one-of choices [ distance [ goal ] of myself ]
    ]
  ][ ;; count (get-section 10 1 10 10) with [self = (patch 10 3)]
    set choice min-one-of choices [ distance [ goal ] of myself ]
  ]
  report choice
end
to create-chemical-ahead
  let che chemical-of-patch-ahead
  ask patches in-cone 1 5 with[pcolor != 38 and intersection? = false][
    set average-chemical che
  ]
end
to create-chemical-left
  let orientation round(heading) mod 360
  if orientation = we [
    set heading 0
    create-chemical-ahead
    set heading we
  ]
  if orientation = ew[
    set heading 180
    create-chemical-ahead
    set heading ew
  ]
  if orientation = ns[
    set heading 90
    create-chemical-ahead
    set heading ns
  ]
  if orientation = sn[
    set heading 270
    create-chemical-ahead
    set heading sn
  ]
end
to create-chemical-right
  let orientation round(heading) mod 360
  if orientation = we [
    set heading 180
    create-chemical-ahead
    set heading we
  ]
  if orientation = ew[
    set heading 0
    create-chemical-ahead
    set heading ew
  ]
  if orientation = ns[
    set heading 270
    create-chemical-ahead
    set heading ns
  ]
  if orientation = sn[
    set heading 90
    create-chemical-ahead
    set heading sn
  ]
end
to-report chemical-of-patch-ahead
  ;ask patches in-cone 15 5 with[pcolor != 38 and intersection? = false] [set pcolor blue]
  report mean [chemical] of patches in-cone floor(grid-x-inc) 10 with[pcolor != 38 and intersection? = false]
end
to-report chemical-of-patch-left
  let orientation round(heading) mod 360
  if orientation = we [
    set heading 0
    let che chemical-of-patch-ahead
    set heading we
    report che
  ]
  if orientation = ew[
    set heading 180
    let che chemical-of-patch-ahead
    set heading ew
    report che
  ]
  if orientation = ns[
    set heading 90
    let che chemical-of-patch-ahead
    set heading ns
    report che
  ]
  if orientation = sn[
    set heading 270
    let che chemical-of-patch-ahead
    set heading sn
    report che
  ]
end
to-report chemical-of-patch-right
  let orientation round(heading) mod 360
  if orientation = we [
    set heading 180
    let che chemical-of-patch-ahead
    set heading we
    report che
  ]
  if orientation = ew[
    set heading 0
    let che chemical-of-patch-ahead
    set heading ew
    report che
  ]
  if orientation = ns[
    set heading 270
    let che chemical-of-patch-ahead
    set heading ns
    report che
  ]
  if orientation = sn[
    set heading 90
    let che chemical-of-patch-ahead
    set heading sn
    report che
  ]
end

to-report right-patch[ dis ]
  report patch-right-and-ahead 90 dis
end
to-report left-patch[ dis ]
  report patch-right-and-ahead -90 dis
end

to-report back-patch[ dis ] ;; este no sirve xd
  let choices neighbors4 with[ pcolor != 38]
  report one-of choices with[self != [patch-ahead 1] of myself and self != [left-patch 1] of myself and self != [right-patch 1] of myself]
end

to-report get-section [x1 y1 x2 y2]
  report patches with[pxcor >= x1 and pxcor <= x2 and pycor >= y1 and pycor <= y2]
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
656
447
-1
-1
4.0
1
12
1
1
1
0
1
1
1
-53
53
-53
53
1
1
1
ticks
30.0

BUTTON
7
46
80
79
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
10
109
43
grid-size-x
grid-size-x
0
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
112
10
214
43
grid-size-y
grid-size-y
0
20
7.0
1
1
NIL
HORIZONTAL

SLIDER
7
83
179
116
num-cars
num-cars
0
1500
506.0
1
1
NIL
HORIZONTAL

SLIDER
8
118
180
151
speed_limit
speed_limit
0
3
3.0
1
1
NIL
HORIZONTAL

BUTTON
83
47
146
80
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
119
299
206
332
go-step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1080
341
1280
491
Velocidad
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"flujo libre" 1.0 0 -7500403 true "" ""
"p/t" 1.0 0 -2674135 true "" ""

PLOT
664
185
864
335
Densidad local
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""

PLOT
874
341
1074
490
Velocidad Vs Densidad
Velocidad
Densidad
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"punto" 1.0 0 -16777216 true "" ""

PLOT
872
28
1072
178
Flujo local
NIL
NIL
0.0
10.0
0.0
0.4
true
false
"" ""
PENS
"real" 1.0 0 -16777216 true "" ""
"medio" 1.0 0 -7500403 true "" ""

PLOT
664
340
864
490
Densidad Vs Flujo
density
flow
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""

PLOT
872
185
1072
335
Flujo Vs Velocidad
Flujo
Velocidad
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""

PLOT
1079
32
1279
182
Flujo global
NIL
NIL
0.0
10.0
0.0
0.4
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""
"mean" 1.0 0 -7500403 true "" ""

MONITOR
10
291
84
336
Densidad
(count turtles / count patches with[pcolor != 38])
4
1
11

PLOT
1080
186
1280
336
DMR
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" "\nif not empty? global-patches-traveled-list[\n    plotxy ticks mean global-patches-traveled-list ;* mean [speed] of turtles\n]\n"

PLOT
6
334
206
484
Viajes realizados
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""

TEXTBOX
797
10
947
28
Locales de una sección
12
0.0
1

TEXTBOX
1158
10
1308
28
Globales
12
0.0
1

PLOT
668
29
868
179
Velocidad local
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"plot" 1.0 0 -16777216 true "" ""

SLIDER
7
154
179
187
reduce-speed-p
reduce-speed-p
0
1
0.3
.5
1
NIL
HORIZONTAL

SLIDER
6
190
180
223
chemical-increment
chemical-increment
0
1
0.1
.05
1
NIL
HORIZONTAL

SLIDER
6
225
178
258
chemical-decrement
chemical-decrement
0
1
0.2
.05
1
NIL
HORIZONTAL

SLIDER
7
260
179
293
max-chemical
max-chemical
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
219
456
391
489
cars_afected
cars_afected
0
1
1.0
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
true
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

car2
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car3
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
