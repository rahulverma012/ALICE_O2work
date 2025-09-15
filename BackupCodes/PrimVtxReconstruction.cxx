  TLorentzVector daughter1, daughter2, mother;
  template<int particleMode, int posPidMode, int negPidMode, typename H, typename T, typename V>
  void checkPairInvMass(H& histReg, const T& posTrack, const T& negTrack, V& posDauList, V& negDauList, const int& idMethodPosDau, const int& idMethodNegDau, int& iNTrkPrim, float& fNTrkPrim, float& effWeightSum ){
    float posDauMass = 0, negDauMass = 0; 
    switch (particleMode) {
      case Phi1020:
        posDauMass = MassKPlus;
        negDauMass = MassKPlus;
        break;
      case JPsiToEE:
        posDauMass = MassElectron;
        negDauMass = MassElectron;
        break;
      case JPsiToMuMu:
        posDauMass = MassMuonMinus;
        negDauMass = MassMuonMinus;
        break;
      case KStar892:
        posDauMass = MassKPlus;
        negDauMass = MassPiPlus;
        break;
      case KStar892Bar:
        posDauMass = MassPiPlus;
        negDauMass = MassKPlus;
        break;
      case Rho770:
        posDauMass = MassPiPlus;
        negDauMass = MassPiPlus;
        break;
      default:
        posDauMass = -999, negDauMass = -999;
        break;
    }
    
    //LorentzVecotrApproach for mass
    daughter1.SetXYZM(posTrack.px(), posTrack.py(), posTrack.pz(), posDauMass);
    daughter2.SetXYZM(negTrack.px(), negTrack.py(), negTrack.pz(), negDauMass);
    mother = daughter1 + daughter2;
    float mass = mother.M();

    bool massCheckPassed = false;
    bool fillTrackPassed = false;
    uint16_t flagBit = 0;

    if constexpr (particleMode == Phi1020){
      if(getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkPhi1020, kPrimMassLow) <= mass && mass <= getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkPhi1020, kPrimMassUp)){
        flagBit = 1<<BIT_IS_PHI_1020; massCheckPassed = true;
        if(getCfg<bool>(cfgPrimVtxParticleCuts, kPrimTrkPhi1020, kPrimFillQA)){ fillTrackPassed = true;}
      }
    } else if constexpr (particleMode == JPsiToEE){
      if(getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkJPsiToEE, kPrimMassLow) <= mass && mass <= getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkJPsiToEE, kPrimMassUp)){
        flagBit = 1<<BIT_IS_JPSI_TO_EE; massCheckPassed = true;
        if(getCfg<bool>(cfgPrimVtxParticleCuts, kPrimTrkJPsiToEE, kPrimFillQA)){ fillTrackPassed = true;}
      }
    } else if constexpr (particleMode == KStar892){
      if(getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimMassLow) <= mass && mass <= getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimMassUp)){
        flagBit = 1<<BIT_IS_KSTAR_892; massCheckPassed = true;
        if(getCfg<bool>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimFillQA)){ fillTrackPassed = true;}
      }
    } else if constexpr (particleMode == KStar892Bar){
      if(getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimMassLow) <= mass && mass <= getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimMassUp)){
        flagBit = 1<<BIT_IS_KSTAR_892_BAR; massCheckPassed = true;
        if(getCfg<bool>(cfgPrimVtxParticleCuts, kPrimTrkKStar892, kPrimFillQA)){ fillTrackPassed = true;}
      }
    } else if constexpr (particleMode == Rho770){
      if(getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkRho770, kPrimMassLow) <= mass && mass <= getCfg<float>(cfgPrimVtxParticleCuts, kPrimTrkRho770, kPrimMassUp)){
        flagBit = 1<<BIT_IS_RHO_770; massCheckPassed = true;
        if(getCfg<bool>(cfgPrimVtxParticleCuts, kPrimTrkRho770, kPrimFillQA)){ fillTrackPassed = true;}
      }
    }

    if(massCheckPassed){
      posDauList.emplace_back(posTrack.globalIndex(), idMethodPosDau * intPowersOf10[flagBit], flagBit);
      negDauList.emplace_back(negTrack.globalIndex(), idMethodNegDau * intPowersOf10[flagBit], flagBit);
      float effWeight = 1.0 ;
      iNTrkPrim += 1; fNTrkPrim += effWeight; effWeightSum += effWeight;
      fillPrimVtxParticleQAHistos<particleMode>(histReg, mother, effWeight);
      if(fillTrackPassed){
        float posDauEffWeight = hPtEtaForEffCorrection[posPidMode][kPos]->GetBinContent(hPtEtaForEffCorrection[posPidMode][kPos]->FindBin(posTrack.pt(), posTrack.eta()));
        float negDauEffWeight = hPtEtaForEffCorrection[negPidMode][kNeg]->GetBinContent(hPtEtaForEffCorrection[negPidMode][kNeg]->FindBin(negTrack.pt(), negTrack.eta()));

        if (idMethodPosDau == kTPCidentified) {
          fillDaughterQA<particleMode, posPidMode, kPos, tpcId>(histReg, posTrack, posDauMass, posDauEffWeight);
        } else if (idMethodPosDau == kTPCTOFidentified) {
          fillDaughterQA<particleMode, posPidMode, kPos, tpctofId>(histReg, posTrack, posDauMass, posDauEffWeight);
        } else if (idMethodPosDau == kUnidentified) {
          fillDaughterQA<particleMode, posPidMode, kPos, NoId>(histReg, posTrack, posDauMass, posDauEffWeight);
        }
    
        if (idMethodNegDau == kTPCidentified) {
          fillDaughterQA<particleMode, negPidMode, kNeg, tpcId>(histReg, negTrack, negDauMass, negDauEffWeight);
        } else if (idMethodNegDau == kTPCTOFidentified) {
          fillDaughterQA<particleMode, negPidMode, kNeg, tpctofId>(histReg, negTrack, negDauMass, negDauEffWeight);
        } else if (idMethodNegDau == kUnidentified) {
          fillDaughterQA<particleMode, negPidMode, kNeg, NoId>(histReg, negTrack, negDauMass, negDauEffWeight);
        }
      }
    }//Histogram filling Block
  }
