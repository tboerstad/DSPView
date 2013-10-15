function createColorbar(cLim, cMap, unit)
%CREATECOLORBAR Creates a color bar which visualizes the color map

    cVector=(1:size(cMap,1))';
    yAxis = linspace(cLim(1), cLim(2), length(cVector));
    figure('Position', [360   356   128   568]);
    image(1, flipud(yAxis), cVector)
    set(gca,'YDir','normal')
    ylabel(unit,'FontSize',16);
    set(gca,'YAxisLocation','right');
    set(gca,'XTick',[]);
    set(gca, 'FontSize', 16);
    colormap(cMap);
end

