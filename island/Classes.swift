import UIKit

class MapGenerator{
    
    var map: Map
    var percentageOfLand: UInt8 = 100
    
    init(rows:Int, columns:Int, percentageOfLand: UInt8) {
        self.map = Map(rows: rows, columns: columns)
        self.percentageOfLand = percentageOfLand
    }
    
    func random() -> Map{
        
        for r in 0...self.map.maxRowIndex{
            for c in 0...self.map.maxColumnIndex{
                
                let p = Point()
                p.isLand = arc4random_uniform(100) < UInt32(self.percentageOfLand)
                p.x = r
                p.y = c
                self.map[r,c] = p
            }
        }
        return self.map
    }
}

class Head{
    
    var color: UIColor
    var numericValue: Int
    var emoji: String?
    
    init(number: Int, color: UIColor, emoji: String? = nil){
        self.numericValue = number
        self.color = color
        self.emoji = emoji
    }
}

class Point{
    
    var head: Head?
    var isLand: Bool = false
    var x:Int = 0
    var y:Int = 0
    
    func getColor() -> UIColor{
        guard let color = head?.color else {
            return isLand ? UIColor.black : UIColor.white
        }
        return color
    }
}

class Map {
    let rows: Int, columns: Int
    private var grid: [Point] = []
    
    init(rows: Int, columns: Int, str: String? = nil){
        self.rows = rows
        self.columns = columns
        
        if (str == nil){
            grid = [Point](repeating: Point(), count:rows*columns)
        }
        else{
            grid = deserialize(maxRowsIndex: self.maxRowIndex, maxColsIndex: self.maxColumnIndex, serializedGrid: str!)
        }
    }
    
    //MARK: -
    //MARK: Internal serialize / serialize for debugging
    
    internal func serialize() -> String{
        
        let arrStr = grid.map { p -> String in
            return p.isLand ? "*" : "~"
        }
        return arrStr.joined(separator: ",")
    }
    
    private func deserialize(maxRowsIndex: Int, maxColsIndex: Int, serializedGrid: String) -> [Point]{
        var result: [Point] = []
        let arr = serializedGrid.components(separatedBy: ",")
        
        var i: Int = 0
        for r in 0...maxRowsIndex{
            for c in 0...maxColsIndex{
                
                let p = Point()
                p.isLand = arr[i] == "*"
                p.x = r
                p.y = c
                result.append(p)
                i = i + 1
            }
        }
        
        return result
    }
    
    var maxRowIndex: Int{
        get{
            return self.rows-1
        }
    }
    
    var maxColumnIndex: Int{
        get{
            return self.columns-1
        }
    }
    
    public subscript(index: Int) -> Point?{
        get{
            if !indexIsValid(index: index) {
                return nil
            }
            return grid[index]
        }
        set{
            if (indexIsValid(index: index)){
                grid[index] = newValue!
            }
        }
    }
    
    public subscript(row: Int, column: Int) -> Point? {
        get {
            if !indexIsValid(row: row, column: column){
                return nil
            }
            return grid[(row * columns) + column]
        }
        set {
            if indexIsValid(row: row, column: column){
                grid[(row * columns) + column] = newValue!
            }
        }
    }
    
    //MARK: Reset all point network markings in order to re-run on same map
    
    public func reset(){
        
        for r in 0...self.maxRowIndex{
            for c in 0...self.maxColumnIndex{
                if let p = self[r,c], p.isLand == true {
                    p.head = nil
                }
            }
        }
    }
    
    //MARK: -
    //MARK: Private methods
    private func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row <= self.maxRowIndex && column >= 0 && column <= self.maxColumnIndex
    }
    
    private func indexIsValid(index: Int) -> Bool {
        return index >= 0 && index < (self.rows * self.columns)
    }
    
    func getLandNeighbors(row: Int, column: Int) -> [Point]{
        
        var results:[Point] = []
        
        for coords in [(row-1,column-1),(row-1,column),(row-1,column+1),(row,column+1)]{
            if let p = self[coords.0,coords.1], p.isLand == true{
                results.append(p)
            }
        }
        
        return results
    }
    
    func draw(){
        
        for r in 0...self.maxRowIndex{
            for c in 0...self.maxColumnIndex{
                
                if let p = self[r,c]{
                    
                    if let head = p.head {
                        if let emoji = head.emoji{
                            print("\(emoji)", terminator: "")
                        }
                        else{
                            print("\(head.numericValue)", terminator: "")
                        }
                    }
                    else if p.isLand {
                        print("🍺", terminator: "")
                    }
                    else {
                        print("🌀", terminator: "")
                    }
                }
                if c == self.maxColumnIndex{
                    print("", terminator: "\n")
                }
            }
        }
        print("\n")
    }
}

class IslandFinder{
    
    var map: Map!
    
    var networks:[Int:Head] = [:]
    var networkCounter:Int = 0
    let emojiStack = EmojiStack()
    
    init(map: Map) {
        self.map = map
    }
    
    func getCount(onChange:((_ pointChanged: Point)->())? = nil) -> Int{
        
        networks.removeAll()
        networkCounter = 0
        
        for r in 0...map.maxRowIndex {
            
            for c in 0...map.maxColumnIndex {
                
                guard let currentPoint = map[r,c] else { assertionFailure("out of bounds failure"); return 0}
                
                guard currentPoint.isLand == true else { continue }
                
                if currentPoint.head == nil{
                    networkCounter = networkCounter + 1
                    currentPoint.head = Head(number: networkCounter, color: ColorDifferenciator.random())
                    networks[networkCounter] = currentPoint.head!
                    onChange?(currentPoint)
                }
                
                for neighborLandPoint in map.getLandNeighbors(row: currentPoint.x, column: currentPoint.y){
                    
                    if neighborLandPoint.head == nil{
                        neighborLandPoint.head = currentPoint.head
                        onChange?(neighborLandPoint)
                    }
                    else if !(neighborLandPoint.head! === currentPoint.head!){
                        
                        if (neighborLandPoint.head!.numericValue > currentPoint.head!.numericValue){
                            
                            networks[neighborLandPoint.head!.numericValue] = nil
                            neighborLandPoint.head! = currentPoint.head!
                            
                            //post notification
                            onChange?(neighborLandPoint)
                        }
                        else{
                            networks[currentPoint.head!.numericValue] = nil
                            currentPoint.head! = neighborLandPoint.head!
                            onChange?(currentPoint)
                        }
                    }
                }
            }
        }
        
        return networks.count
    }
    
    func displayNetworks(){
        print(self.networks.map({ k, v -> String in
            return "(\(k):\(v.emoji!))"
        }).joined(separator: ","))
    }

}

class EmojiStack {
    var emojis:[String] = ["❎","🅰","🆎","🆒","🆔","🆚","🈯","🌾","🍚","🍜","🍝","🍞","🍟","🍡","🍵","🍸","🎀","🎁","🎂","🎃","🎄","🎾","🐍","🐵","🐶","🐷","🐸","🐹","🐺","🐻","👀","👙","👶","👿","💊","💚","💩","💪","💰","🔑"]
    
    func peek() -> String?{
        return emojis.last
    }
    
    func pop() -> String? {
        guard (peek() != nil) else { return nil}
        return emojis.removeLast()
    }
}

class ColorDifferenciator{
    
    class func random() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomGreen:CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomBlue:CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
}
