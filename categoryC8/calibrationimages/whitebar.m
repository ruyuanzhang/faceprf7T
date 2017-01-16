for p=1900:-100:1000
  a = placematrix(zeros(1000,1920),ones(100,p),[]);
  imwrite(uint8(255*a),sprintf('%d.png',p));
end
