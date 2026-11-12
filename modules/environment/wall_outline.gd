extends RefCounted
## 从原图黑色边线读取每行墙壁内缘，不改动美术文件。
static var cache: Dictionary = {}
static func read(texture: Texture2D, first_row: int = 0) -> ImageTexture:
	var key:=texture.resource_path+str(first_row)
	if cache.has(key):
		return cache[key]
	var source:=texture.get_image()
	var width:=source.get_width()
	var result:=Image.create(1,source.get_height(),false,Image.FORMAT_RGF)
	for y in range(source.get_height()):
		var left:=0.0
		var right:=1.0
		if y>=first_row:
			for x in range(int(width*0.34),-1,-1):
				var c:=source.get_pixel(x,y)
				if c.a>0.5 and maxf(c.r,maxf(c.g,c.b))<0.09:
					left=float(x+1)/width
					break
			for x in range(int(width*0.66),width):
				var c:=source.get_pixel(x,y)
				if c.a>0.5 and maxf(c.r,maxf(c.g,c.b))<0.09:
					right=float(x)/width
					break
		result.set_pixel(0,y,Color(left,right,0,1))
	var output:=ImageTexture.create_from_image(result)
	cache[key]=output
	return output
