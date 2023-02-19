//
//  Model.swift
//  ModelPickerApp
//
//  Created by 箕作勇輝 on 2/13/23.
//

import RealityKit
import UIKit
import Combine

class Model {
    var modelName: String
    var image: UIImage
    var modelEntity: ModelEntity?
    //cancellable allows you to cancel publicher using cancel()
    private var cancellable: AnyCancellable? = nil
    
    //init でプロパティの初期値を決めれる　受け取る
    init (modelName: String){
        self.modelName = modelName
        //UIimage might be nil so wrap with "!"     image will be the icon on modelPickerView
        self.image = UIImage(named: modelName)!
        //fixing filename to the one with .usdz so that we can use it within modelEntity.loadModel(named: fileName)
        let fileName = modelName + ".usdz"
        
        

        //cancellable is used as pulisher　in combine system
        //https://developer.apple.com/documentation/realitykit/loading-entities-from-a-file
        //https://ethansaadia.medium.com/realitykit-assets-52ada3f9465f
        //asyncronously load files
        self.cancellable = ModelEntity.loadModelAsync(named: fileName).sink(receiveCompletion: {loadCompletion in
            //読み込みが失敗した場合
            print("DEBUG: failed to load model named: \(modelName)")
            
        }, receiveValue: {modelEntity in
            //読み込みが成功した場合
            self.modelEntity = modelEntity
            print("DEBUG: succeed to load model named: \(modelName)")
        })
        
        
    }
    
}

