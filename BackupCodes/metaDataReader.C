TFile* file = TFile::Open("AO2D.root");
TMap* metaData = nullptr;
file->GetObject("metaData", metaData);  // safer than file->Get("metaData")

if (metaData) {
    TIter next(metaData);
    TObjString* key;
    while ((key = (TObjString*)next())) {
        TObjString* value = (TObjString*)metaData->GetValue(key);
        std::cout << key->GetString() << " : " << value->GetString() << std::endl;
    }
} else {
    std::cerr << "metaData not found!" << std::endl;
}
