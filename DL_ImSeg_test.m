% Segment cells

function DL_ImSeg_test
%DL_ImSeg_test

%


% Load in Image Stacks
A(:,:,1,:) = loadtiff('W.tif');
A(:,:,2,:)= loadtiff('R.tif');
A(:,:,3,:) = loadtiff('G.tif');
A(:,:,4,:) = loadtiff('B.tif');

thresholds2use = {4,5,5,4};
ttt = {'White channel','Red channel','Green channel','Blue channel'};

for i = 1: 4
W = double(squeeze(A(:,:,i,:)));

data = max(W,[],3)-mean(imgaussfilt(double(W),3),3);

hblob = vision.BlobAnalysis( ...
                'AreaOutputPort', false, ...
                'BoundingBoxOutputPort', false, ...
                'OutputDataType', 'single', ...
                'MinimumBlobArea', 35, ...
                'MaximumBlobArea', 1000, ...
                'Connectivity', 8, ...
                'MaximumCount', 15000);


            image = imresize(data,1);


    % Apply a combination of morphological dilation and image arithmetic
    % operations to remove uneven illumination and to emphasize the
    % boundaries between the cells.
    y1 = 2*image - imdilate(image, strel('square',7));
    ytemp = y1;
    y1(y1<0) = 0;
    y1(y1>thresholds2use{i}) = 1;
    y2 = imdilate(y1, strel('square',7)) - y1;
    th = graythresh(image);      % Determine threshold using Otsu's method
    y3 = (y2 <= th*0.7);

    Centroid = step(hblob, y3);   % Calculate the centroid
    numBlobs = size(Centroid,1);  % and number of cells.
    % Display the number of frames and cells.
    frameBlobTxt = sprintf('Frame %d, Count %d', 'one', numBlobs);
    image = insertText(image, [1 1], frameBlobTxt, ...
            'FontSize', 16, 'BoxOpacity', 0, 'TextColor', 'white');
    image = insertText(image, [1 size(image,1)],'wtf is this', ...
            'FontSize', 10, 'AnchorPoint', 'LeftBottom', ...
            'BoxOpacity', 0, 'TextColor', 'white');

    % Display video
    image_out = insertMarker(data, Centroid, 'o','Size',10,'Color', 'green');

    counter = 1;
    % Get rid of nearby ROIs by merging them

%         figure(); imagesc(image_out)

figure();
subplot(131)
im2show = squeeze(mean(A(:,:,2:4,:),4));
imshow(im2show/100);
hold on;
plot(Centroid(:,1),Centroid(:,2),'ro')
subplot(132)
imagesc(ytemp);
hold on;
plot(Centroid(:,1),Centroid(:,2),'ro')
axis equal tight

subplot(133)
imagesc(data);
hold on;
plot(Centroid(:,1),Centroid(:,2),'ro')
axis equal tight
title(ttt{i});


        Cent2save{i} = Centroid;

        clear Centroid numBlobs y1 y2 y3 data
end



% Calculate nearby vals:
try
% white and green
P = Cent2save{1};
PQ = Cent2save{3};
[k pdist] = dsearchn(P,PQ);

WhiteGreenCells = P(k(find(pdist<9)),:);
clear P Q
% white and red
P = WhiteGreenCells;
PQ = Cent2save{2};
[kbad pdist2] = dsearchn(P,PQ);

RedCells = WhiteGreenCells(kbad(find(pdist2<15)),:);


figure();
im2show = squeeze(mean(A(:,:,2:4,:),4));
im2show2 = squeeze(mean(A(:,:,1,:),4));
im2show = im2show+im2show2;
imshow(im2show/100);
hold on;
plot(WhiteGreenCells(:,1),WhiteGreenCells(:,2),'wo','MarkerSize',10,'LineWidth',3)
plot(RedCells(:,1),RedCells(:,2),'*r','MarkerSize',10,'LineWidth',3)



figure();
for ii = 1:4;
h(ii) = subplot(1,4,ii);
im2show3 = squeeze(mean(A(:,:,ii,:),4));
imshow(im2show3/100);
hold on;
plot(WhiteGreenCells(:,1),WhiteGreenCells(:,2),'bo','MarkerSize',10,'LineWidth',3)
plot(RedCells(:,1),RedCells(:,2),'*r','MarkerSize',10,'LineWidth',3)
title(ttt{ii});
linkaxes(h);

end

catch
    disp(' NO CELLS DETECTED');
end
