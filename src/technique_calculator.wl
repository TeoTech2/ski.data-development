(* Ski Technique Calculator - Cross Country Skiing *)
(* Calculate time on course based on optimal technique selection *)

(* Custom speed graphs as a % of maximum speed vs. inclination for v1 and v2 *)
v1SpeedGraph = Table[i/100 -> {.35 + Tanh[i/40], "v1"}, {i, 0, 20}];
v2SpeedGraph = Table[i/100 -> {1 - Tanh[i/40] + PDF[NormalDistribution[.25, .1], i/100]/20, "v1"}, {i, 0, 20}];
(*v2SpeedGraph=Table[g[i/100,3]->{g[1-Tanh[i/40],3],"v2"},{i,0,20}]*)

(* Maximum speed in meters/second *)
maxSpeed = 4.47;

diffy = 30;

(* Calculate distance tables *)
distanceTables = Table[Sqrt[((fitFunc[i + diffy] - fitFunc[i])^2 + diffy^2)], {i, 1, 5000, diffy}];

(* Extract slope data *)
slopeTable = Table[Values[elevationSlopeData[[i]]], {i, Length[elevationSlopeData]}];

(* Calculate total distance *)
Total[Table[distanceTables[[i]], {i, Length[distanceTables]}]];

(* Determine best approach based on efficiency *)
bestApproachEff = Table[
  If[Values[v2SpeedGraph[[i]]][[1]] > Values[v1SpeedGraph[[i]]][[1]], 
    Keys[v2SpeedGraph[[i]]] -> {Values[v2SpeedGraph[[i]]][[1]], Values[v2SpeedGraph[[i]]][[2]]}, 
    Keys[v1SpeedGraph[[i]]] -> {Values[v1SpeedGraph[[i]]][[1]], Values[v1SpeedGraph[[i]]][[2]]}
  ], 
  {i, Length[v1SpeedGraph]}
];

(* Select best technique for each course section *)
bestPart = Table[
  Last[Switch[
    Select[bestApproachEff, slopeTable[[i]] > Keys[#1] &], 
    {}, 0 -> {1.25, "v2-alt"}, 
    Except[_Empty], Last[Select[bestApproachEff, slopeTable[[i]] > Keys[#1] &]]
  ]], 
  {i, Length[slopeTable]}
];

(* Calculate race time *)
Print["Minutes on Race Course ~ Sum* Delta_Distance * 1/Eff. * 1/Max Speed ~ Sum* Delta_Distance * speed. Div 60"]

(* Total race time in minutes *)
raceTimeMinutes = Total[
  Table[Take[distanceTables, 166][[i]]/bestPart[[i]][[1]]*(1/maxSpeed), 
    {i, Length[bestPart]}]
]/60;

(* Create color-coded visualization *)
bestPart[[1]][[2]]
colorList = Table[
  {{elevationSlopeData[[i]][[1]][[1]], elevationSlopeData[[i]][[1]][[2]]} -> 
    Switch[bestPart[[i]][[2]], 
      "v2", RGBColor[1, 0, 0], 
      "v1", RGBColor[0, 0, 1], 
      "v2-alt", Orange]}, 
  {i, Length[kind]}
];

(* Extract height data *)
heightData = Table[fitFunc[elevationSlopeData[[i]][[1]][[1]]], {i, Length[kind]}];

(* Prepare colored range for visualization *)
coloredRange = Table[
  {Keys[colorList[[j]][[1]]][[1]], Keys[colorList[[j]][[1]]][[2]], Values[colorList[[j]]][[1]]}, 
  {j, Length[colorList]}
];

(* Create visualization of race course with color-coded technique sections *)
Show[
  Table[Plot[
    fitFunc[x], 
    {x, Keys[colorList[[j]]][[1]][[1]], Keys[colorList[[j]]][[1]][[2]]}, 
    PlotStyle -> Values[colorList[[j]]][[1]], 
    PlotRange -> {{0, 5000}, {250, 310}}
  ], 
  {j, Length[coloredRange]}], 
  PlotLabel -> Style["Race Course-> Red: Opt. v2, Blue: Opt. v1, Downhill:v2-alt", FontSize -> 18, FontFamily -> "Helvetica"], 
  AxesLabel -> {"Len. (m)", "Hgt. (m)"}, 
  ImageSize -> Full, 
  AspectRatio -> 1/4
]

(* Create efficiency graphs automatically based on data *)
w[x_, n_] := Round[x, 0.01]

(* Linear Regression model for predicting efficiency *)
p = Predict[{.07 -> 1.05, .10 -> .92}, Method -> "LinearRegression"];

(* Compute data for visualization *)
compData = MapThread[Rule, {(Range[15] * .01), If[p[#] > 1, "v2", "v1"] & /@ (Range[15] * .01)}];

(* Classify techniques based on computed data *)
selector = Classify[compData];
