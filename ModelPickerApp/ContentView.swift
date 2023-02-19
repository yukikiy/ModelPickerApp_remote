//
//  ContentView.swift
//  ModelPickerApp
//
//  Created by 箕作勇輝 on 2/4/23.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    //turn on placement button and off
    @State private var isPlacementEnabled = false
    @State private var selectedModel :Model?
    @State private var modelConfirmedForPlacement :Model?

    //Dinamically get names of files from directory
    //https://qiita.com/taji-taji/items/fd46d9a04ef50386fcca how to use intializing closure
    private var models: [Model] = {
        let fileManager = FileManager.default
        //files are supposed to include selected files
        guard let path = Bundle.main.resourcePath, let files = try? fileManager.contentsOfDirectory(atPath: path) else {
            return[]
        }

        var availableModels: [Model] = []
        //only when file has .usdz suffix
        for filename in files where filename.hasSuffix(".usdz"){
            //remove .usdz from file name and put it into availableModels array
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            //引数を渡しつつインスタンスを生成　Modelのinit()にmodelNameが渡される
            let model = Model(modelName: modelName)
            //availbleModels are file name without .usdz suffix
            availableModels.append(model)
        }
        return availableModels
        
    }()
    //this is main body
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            
            //if item is selected, placement button will show up(isPlacementEnabled)
            if self.isPlacementEnabled{
                placementButtonView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models )
            }
       
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    //first setting of AR
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        //set up configuration and run it by arView.session.run
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        //this sets light setting automatically
        config.environmentTexturing = .automatic
        //if the LIDAR is available, turn it on
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        //using FocusEntity package
        let focusEntity = FocusEntity(on: arView, focus: .plane)
        arView.scene.anchors.append(focusEntity)
        
        arView.session.run(config)
        return arView
    }
    
    //render modelEntity   model = modelConfirmedPlacment = selectedModel = models[index] = [Model][index]
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = self.modelConfirmedForPlacement{
            
            if let modelEntity = model.modelEntity{
                print("DEBUG: adding model:\(model.modelName) to scene ")
                //modelEntity needs to be attached to anhorEntity
                let anchorEntity = AnchorEntity(plane: .any)
                //put modelEntity on anchor
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                //render on iphone screen
                uiView.scene.addAnchor(anchorEntity)
                      
            } else {
                print("DEBUG: failed to add model:\(model.modelName) to scene")
            }
            
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
    
    
}


struct ModelPickerView : View {
    //using @Binding allows you to use variable from other functions
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    //models is array that includes modelName, image, modelEntity
    var models: [Model]
    
    //when pickerView is tapped pass selectedModel has tapped modelName,image,modelEntity
    var body: some View{
        ScrollView(.horizontal , showsIndicators: false){
            HStack(spacing: 30){
                ForEach(0 ..< self.models.count     ){
                    index in
                    
                    Button(action:{
                        print("DEBUG: selected item: \(self.models[index].modelName)")
                        self.isPlacementEnabled = true
                        self.selectedModel = models[index]
                        
                    })
                    
                    {
                        Image(uiImage: self.models[index].image)
                        .resizable()
                        .frame(height: 150)
                        .aspectRatio(1/1, contentMode: .fit)
                        .background(Color.white)
                        .cornerRadius(10)
                     
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
    
    
}

struct placementButtonView : View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    func resetPlacementParameter(){
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
    
    var body: some View{
        HStack{
            Button(action: {
                print("DEBUG: canceled")
                resetPlacementParameter()
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 60 , height: 60)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .font(.title)
                    .padding(1)
            })
            
            Button(action: {
                print("DEBUG: confirmed")
                self.modelConfirmedForPlacement = self.selectedModel
                
                resetPlacementParameter()
            }, label: {
                Image(systemName: "checkmark")
                    .frame(width: 60 , height: 60)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .font(.title)
                    .padding(1)
            })
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
