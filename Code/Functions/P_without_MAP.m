function Peripheral_newout = P_without_MAP(comb_matrix1, Pressure_selection)
 
 %Sort based on difference from Pressure selection specifically for P. Dont worry about MAP.
 cm_forP =  comb_matrix1(comb_matrix1(:,1)> Pressure_selection(2,1)-10 & comb_matrix1(:,1)< Pressure_selection(2,1)+10, :);
 cm_forP1 =  cm_forP(cm_forP(:,2)> Pressure_selection(2,2)-10 & cm_forP(:,2)< Pressure_selection(2,2)+10, :);
 cm_forP2 =  cm_forP1(cm_forP1(:,3)> Pressure_selection(2,3)-10 & cm_forP1(:,3)< Pressure_selection(2,3)+10, :);
 cm_forP3 =  cm_forP1(cm_forP1(:,4)> Pressure_selection(2,4)-10 & cm_forP1(:,4)< Pressure_selection(2,4)+10, :);
 
 % Get differences from sys and dia, and MAP
 for i = 1:size(cm_forP3,1)
     for j = 1:6
         diffcm_forP3(i,j)= cm_forP3(i,j)- Pressure_selection(2,j);
     end
     diffcm_forP3(i,7)= sum(diffcm_forP3(i, 1:4)); %differences of sys and dia
     diffcm_forP3(i,8)= sum(diffcm_forP3(i, 5:6)); %differences ofMAP
 end
 
 meandiff_sysdia_fcm_forP3 = round(mean(abs(diffcm_forP3(:,7))));
 SDdif_sysdia_fcm_forP3= round(std(abs(diffcm_forP3(:,7))));
 
 meandiff_MAP_fcm_forP3 = round(mean(abs(diffcm_forP3(:,8))));
 SDdif_MAP_fcm_forP3= round(std(abs(diffcm_forP3(:,8))));
 
 %short list based on min diff from all sys dia
 
 for i=1:size(diffcm_forP3,1)
     cm_forP3_logical (i,1)= abs(diffcm_forP3(i, 7))< meandiff_sysdia_fcm_forP3;
 end
 
 cm_forP4 = cm_forP3(cm_forP3_logical, :);
 
 %short list based on min diff from high dia and low sys
 for i = 1:size(cm_forP4,1)
     for j = [1,4]
         diffcm_forP4(i,j)= cm_forP4(i,j)- Pressure_selection(2,j);
     end
     diffcm_forP4(i,5)= sum(abs(diffcm_forP4(i, 1:4))); %differences of lowsys and highdia
 end
 
 meandiff_LSHD_forP4 = round(mean(diffcm_forP4(:,5)));
 SDdiff_highdia_cm_forP4 = round(std(abs(diffcm_forP4(:,5))));
 
 for i=1:size(cm_forP4,1)
     cm_forP4_logical(i,1)= (abs(cm_forP4(i,1)- Pressure_selection(2,1))+ abs(cm_forP4(i,4)- Pressure_selection(2,4)))< (meandiff_LSHD_forP4 - SDdiff_highdia_cm_forP4);
 end
 
 cm_forP5 = cm_forP4(cm_forP4_logical, :);
 
 if size(cm_forP5,1)>10
     cm_forP5 =[];
     for i=1:size(cm_forP4,1)
         cm_forP4_logical(i,1)= (abs(cm_forP4(i,1)- Pressure_selection(2,1))+ abs(cm_forP4(i,4)- Pressure_selection(2,4)))< (meandiff_LSHD_forP4 - SDdiff_highdia_cm_forP4)/2;
     end
     cm_forP5 = cm_forP4(cm_forP4_logical, :);
 end
 
 if size(cm_forP5,1)>10
     cm_forP5 =[];
     for i=1:size(cm_forP4,1)
         cm_forP4_logical(i,1)= (abs(cm_forP4(i,1)- Pressure_selection(2,1))+ abs(cm_forP4(i,4)- Pressure_selection(2,4)))< (meandiff_LSHD_forP4 - SDdiff_highdia_cm_forP4)/4;
     end
     cm_forP5 = cm_forP4(cm_forP4_logical, :);
 end
 
 
 for i = 1:size(cm_forP5,1)
     cm_forP5_logical(i,1) = cm_forP5(i,5)<cm_forP5(i,6);
 end
 
 cm_forP6 = cm_forP5(cm_forP5_logical, :);
 for i = 1:size(cm_forP6,1)
     for j = 3:4
         diffcm_forP6(i,j)= cm_forP6(i,j)- min(Pressure_selection(1:2,j));
     end
     diffcm_forP6(i,5)= sum(abs(diffcm_forP6(i, 1:4))); %differences of lowsys and highdia
 end
 
 [~,rIcm_forP6] = min(diffcm_forP6(i,5));
 Peripheral_newout = cm_forP6(rIcm_forP6,:);
 end
 