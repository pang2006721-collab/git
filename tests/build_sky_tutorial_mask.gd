extends SceneTree
func _initialize():
    var source=load("res://assets/art/ui/tutorial_frames.jpg").get_image()
    var crop=source.get_region(Rect2i(254,2708,824,532))
    crop.convert(Image.FORMAT_RGB8)
    var data=crop.get_data()
    var width:=824
    var height:=532
    var visited=PackedByteArray()
    visited.resize(width*height)
    var queue=PackedInt32Array([266*width+412])
    visited[queue[0]]=255
    var head:=0
    while head<queue.size():
        var index:int=queue[head]
        head+=1
        for neighbor in [index-1,index+1,index-width,index+width]:
            if neighbor<0 or neighbor>=width*height or abs(neighbor%width-index%width)>1 or visited[neighbor]>0:continue
            var offset:int=neighbor*3
            if mini(data[offset],mini(data[offset+1],data[offset+2]))>150:
                visited[neighbor]=255
                queue.append(neighbor)
    var expanded=visited.duplicate()
    for index in queue:
        for dy in range(-2,3):
            for dx in range(-2,3):
                var x:int=index%width+dx
                var y:int=index/width+dy
                if x>=0 and x<width and y>=0 and y<height:expanded[y*width+x]=255
    var mask=Image.create_from_data(width,height,false,Image.FORMAT_L8,expanded)
    mask.save_png("res://assets/art/ui/tutorial_sky_hole.png")
    print("SKY_HOLE_MASK pixels=",queue.size())
    quit()
