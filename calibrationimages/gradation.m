vals0 = uint8(0:5:255);
name = 'gradationlinear.png';

vals0 = uint8(normalizerange(linspace(0,1,52) .^ 2,0,255,0,1));
name = 'gradationquadratic.png';

black = repmat(vals0,[1 1 3]);
red = cat(3,vals0,zeros(size(vals0)),zeros(size(vals0)));
green = cat(3,zeros(size(vals0)),vals0,zeros(size(vals0)));
blue = cat(3,zeros(size(vals0)),zeros(size(vals0)),vals0);

im = processmulti(@imresize,cat(1,black,red,green,blue),[4*100 length(vals)*10],'nearest');
imwrite(im,name);
