sfs = logspace(log10(1),log10(256),17);
for p=1:length(sfs)
  imwrite(uint8(255*(.75*(makegrating2d(512,sfs(p),pi/2,0)/2) + .5)),sprintf('sf%02d.png',p));
end
