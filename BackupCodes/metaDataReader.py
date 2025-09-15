import ROOT

f = ROOT.TFile.Open("AO2D.root")
meta = f.Get("metaData")

for key in meta:
    val = meta.GetValue(key)
    print(f"{key.GetName()} : {val.GetName()}")
