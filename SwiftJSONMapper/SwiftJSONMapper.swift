//
//  JsonParser.swift
//  EntertainNow
//
//  Created by Umut Uzgur on 17/06/15.
//  Copyright (c) 2015 Umut Uzgur. All rights reserved.
//

import Foundation

class JsonParser <T: NSObject > {
    
    var parsingMap = [String:AnyObject]()
    
    
    init(){
        parsingMap = createClassTree(T)
    }
    
    func createClassTree(clazz : AnyClass) -> [String: AnyObject]{
        var currentTree = [String:AnyObject]()
        var example: AnyObject = clazz.new()
        let reflectMap = reflect(example)
        for var i = 0; i < reflectMap.count; i++ {
            if(reflectMap[i].0 != "super"){
                if let type: AnyClass = reflectMap[i].1.valueType as? AnyClass{
                    currentTree[reflectMap[i].0] = ["\(type)" , createInnerClassTree(type)]
                }else{
                    if(JsonParser.isArray(reflectMap[i].1.value)){
                        let start = "\(reflectMap[i].1.valueType)".rangeOfString("<")?.endIndex
                        let end = "\(reflectMap[i].1.valueType)".rangeOfString(">")?.startIndex
                        let className = "\(reflectMap[i].1.valueType)".substringWithRange(Range(start: start!, end: end!))
                        currentTree[reflectMap[i].0] = ["Swift.Array", className , createInnerClassTree(NSClassFromString(className))]
                        
                    }else if(JsonParser.isDictionary(reflectMap[i].1.value)){
                        println("Dictinoary")
                    }else{
                        currentTree[reflectMap[i].0] = "\(reflectMap[i].1.valueType)"
                    }
                }
            }
        }
        return currentTree
    }
    
    func createInnerClassTree(clazz : AnyClass) -> [String: AnyObject]{
        
        var object: AnyObject = clazz.new()
        let reflectMap = reflect(object)
        var currentTree = [String: AnyObject]()
        for var i = 0; i < reflectMap.count; i++ {
            if(reflectMap[i].0 != "super"){
                //TODO check performence of object checking
                if let type: AnyClass = reflectMap[i].1.valueType as? AnyClass{
                    currentTree[reflectMap[i].0] = ["\(type)" , createInnerClassTree(type)]
                }else{
                    if(JsonParser.isArray(reflectMap[i].1.value)){
                        let start = "\(reflectMap[i].1.valueType)".rangeOfString("<")?.endIndex
                        let end = "\(reflectMap[i].1.valueType)".rangeOfString(">")?.startIndex
                        let className = "\(reflectMap[i].1.valueType)".substringWithRange(Range(start: start!, end: end!))
                        currentTree[reflectMap[i].0] = ["Swift.Array", className , createInnerClassTree(NSClassFromString(className))]
                        
                    }else if(JsonParser.isDictionary(reflectMap[i].1.value)){
                        println("Dictinoary")
                    }else{
                        currentTree[reflectMap[i].0] = "\(reflectMap[i].1.valueType)"
                    }
                }
            }
        }
        return currentTree
    }
    
    
    
    
    
    
    func parseJSONtoModelList(data : NSData) -> [T] {
        var json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as! [[String: AnyObject]]
        
        var models : [T] = []
        for object in json as [AnyObject]  {
            var model = T.new()
            for (field,type) in parsingMap {
                if let value: AnyObject = object[field] {
                    if let className = type as? String {
                        model.setValue(value, forKey: field)
                    }else{
                        if(JsonParser.isNameArray((type as! [AnyObject])[0] as! String)){
                            model.setValue(parseJSONLeafToList(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                        }else{
                            model.setValue(parseJSONLeafToModel(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                        }
                    }
                }
            }
            models.append(model)
        }
        
        return models
        
    }
    
    
    func parseJSONLeafToList(json : AnyObject, parseMapLeaf : [AnyObject]) -> [AnyObject] {
        var modelClass: AnyClass! = NSClassFromString(parseMapLeaf[1] as! String)
        var models = [AnyObject]()
        
        for object in json as! [AnyObject]  {
            var model: AnyObject = modelClass.new()
            for (field,type) in parseMapLeaf[2] as! [String: AnyObject] {
                if let value: AnyObject = object[field] {
                    if let className = type as? String {
                        model.setValue(value, forKey: field)
                    }else{
                        if(JsonParser.isNameArray((type as! [AnyObject])[0] as! String)){
                            model.setValue(parseJSONLeafToList(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                        }else{
                            model.setValue(parseJSONLeafToModel(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                        }
                        
                    }
                }
            }
            models.append(model)
        }
        
        return models
        
        
    }
    
    func parseJSONtoModel(data : NSData) -> T {
        var json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as! [String: AnyObject]
        
        var model = T.new()
        for (field,type) in parsingMap{
            if let value: AnyObject = json[field] {
                if let className = type as? String {
                    model.setValue(value, forKey: field)
                }else{
                    if(JsonParser.isNameArray((type as! [AnyObject])[0] as! String)){
                        model.setValue(parseJSONLeafToList(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                    }else{
                        model.setValue(parseJSONLeafToModel(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                    }
                    
                }
            }
        }
        return model
        
        
    }
    
    
    func parseJSONLeafToModel(json : AnyObject, parseMapLeaf : [AnyObject]) -> AnyObject {
        var modelClass: AnyClass! = NSClassFromString(parseMapLeaf[0] as! String)
        
        var model: AnyObject = modelClass.new()
        for (field,type) in (parseMapLeaf[1] as! [String : AnyObject]){
            if let value: AnyObject = json[field] {
                if let className = type as? String {
                    model.setValue(value, forKey: field)
                }else{
                    if(JsonParser.isNameArray((type as! [AnyObject])[0] as! String)){
                        model.setValue(parseJSONLeafToList(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                    }else{
                        model.setValue(parseJSONLeafToModel(value, parseMapLeaf: type as! [AnyObject]), forKey: field)
                    }
                    
                }
            }
        }

        return model
        
    }
    func arrayToJSON(models : [AnyObject] , parsingMapLeaf: [String: AnyObject]) -> [AnyObject] {
        var currentArray = [AnyObject]()
        for model in models {
            var currentDict: [String: AnyObject] = NSDictionary() as! [String : AnyObject]
            
            for (field,value) in parsingMapLeaf {
                let currentField: AnyObject = model.valueForKey(field)!
                if(JsonParser.isPrimitive(currentField)){
                    currentDict[field] = currentField
                }else if(JsonParser.isDictionary(currentField)){
                    println("Dictionary")
                }else if(JsonParser.isArray(currentField)){
                    currentDict[field] = arrayToJSON(currentField as! [AnyObject] , parsingMapLeaf: value[2] as! [String: AnyObject])
                    println("Array")
                }else{
                    var innerDict = [String: AnyObject]()
                    var innerObject = value[1] as! [String: AnyObject]
                    for innerField in innerObject.keys{
                        innerDict[innerField] = currentField.valueForKey(innerField)
                    }
                    currentDict[field] = innerDict
                }
            }
            currentArray.append(currentDict)
        }
        return currentArray
        
    }
    
    
    
    
    func toJSON(model : T) -> NSData {
        var dict: [String: AnyObject] = NSDictionary() as! [String : AnyObject]
        for (field,value) in parsingMap {
            let currentField: AnyObject = model.valueForKey(field)!
            if(JsonParser.isPrimitive(currentField)){
                dict[field] = currentField
            }else if(JsonParser.isDictionary(currentField)){
                println("Dictionary")
            }else if(JsonParser.isArray(currentField)){
                dict[field] = arrayToJSON(currentField as! [AnyObject] , parsingMapLeaf: value[2] as! [String: AnyObject])
            }else{
                var innerDict = [String: AnyObject]()
                var innerObject = value[1] as! [String: AnyObject]
                for innerField in innerObject.keys{
                    innerDict[innerField] = currentField.valueForKey(innerField)
                }
                dict[field] = innerDict
            }
        }
        
        return NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted, error: nil)!
    }
    
    
    class func isPrimitive(object: Any) -> Bool{
        if(object is String){
            return true
        }else if(object is Bool){
            return true
        }else if(object is Float){
            return true
        }else if(object is Int){
            return true
        }else{
            return false
        }
        
    }
    class func isArray(object: Any) -> Bool{
        return object is NSArray
        
    }
    class func isDictionary(object: Any) -> Bool{
        return object is NSDictionary
        
    }
    class func isNameDictionary(objectName: String) -> Bool{
        return objectName == "Swift.Dictionary"
        
    }
    
    class func isNameArray(objectName: String) -> Bool{
        return objectName.hasPrefix( "Swift.Array")
        
    }
    
    
    deinit {
        println("Json Parser deinit \(toString(T))")
    }
}