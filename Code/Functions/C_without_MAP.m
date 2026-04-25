
 function Central_newout = C_without_MAP(comb_matrix1, Pressure_selection) 
 %Sort based on difference from Cressure selection specifically for C. Dont worry about MAC.
 cm_forC =  comb_matrix1(comb_matrix1(:,1)> Pressure_selection(1,1)-10 & comb_matrix1(:,1)< Pressure_selection(1,1)+10, :);
 cm_forC1 =  cm_forC(cm_forC(:,2)> Pressure_selection(1,2)-10 & cm_forC(:,2)< Pressure_selection(1,2)+10, :);
 cm_forC2 =  cm_forC1(cm_forC1(:,3)> Pressure_selection(1,3)-10 & cm_forC1(:,3)< Pressure_selection(1,3)+10, :);
 cm_forC3 =  cm_forC1(cm_forC1(:,4)> Pressure_selection(1,4)-10 & cm_forC1(:,4)< Pressure_selection(1,4)+10, :);
 
 % Get differences from sys and dia, and MAC
 for i = 1:size(cm_forC3,1)
     for j = 1:6
         diffcm_forC3(i,j)= cm_forC3(i,j)- Pressure_selection(1,j);
     end
     diffcm_forC3(i,7)= sum(diffcm_forC3(i, 1:4)); %differences of sys and dia
     diffcm_forC3(i,8)= sum(diffcm_forC3(i, 5:6)); %differences ofMAC
 end
 
 meandiff_sysdia_fcm_forC3 = round(mean(abs(diffcm_forC3(:,7))));
 SDdif_sysdia_fcm_forC3= round(std(abs(diffcm_forC3(:,7))));
 
 meandiff_MAC_fcm_forC3 = round(mean(abs(diffcm_forC3(:,8))));
 SDdif_MAC_fcm_forC3= round(std(abs(diffcm_forC3(:,8))));
 
 %short list based on min diff from all sys dia
 
 for i=1:size(diffcm_forC3,1)
     cm_forC3_logical (i,1)= abs(diffcm_forC3(i, 7))< meandiff_sysdia_fcm_forC3;
 end
 
 cm_forC4 = cm_forC3(cm_forC3_logical, :);
 
 %short list based on min diff from high dia and low sys
 for i = 1:size(cm_forC4,1)
     for j = [1,4]
         diffcm_forC4(i,j)= cm_forC4(i,j)- Pressure_selection(1,j);
     end
     diffcm_forC4(i,5)= sum(abs(diffcm_forC4(i, 1:4))); %differences of lowsys and highdia
 end
 
 meandiff_LSHD_forC4 = round(mean(diffcm_forC4(:,5)));
 SDdiff_highdia_cm_forC4 = round(std(abs(diffcm_forC4(:,5))));
 
 for i=1:size(cm_forC4,1)
     cm_forC4_logical(i,1)= (abs(cm_forC4(i,1)- Pressure_selection(1,1))+ abs(cm_forC4(i,4)- Pressure_selection(1,4)))< (meandiff_LSHD_forC4 - SDdiff_highdia_cm_forC4);
 end
 
 cm_forC5 = cm_forC4(cm_forC4_logical, :);
 
 if size(cm_forC5,1)>10
     cm_forC5 =[];
     for i=1:size(cm_forC4,1)
         cm_forC4_logical(i,1)= (abs(cm_forC4(i,1)- Pressure_selection(1,1))+ abs(cm_forC4(i,4)- Pressure_selection(1,4)))< (meandiff_LSHD_forC4 - SDdiff_highdia_cm_forC4)/2;
     end
     cm_forC5 = cm_forC4(cm_forC4_logical, :);
 end
 
 if size(cm_forC5,1)>10
     cm_forC5 =[];
     for i=1:size(cm_forC4,1)
         cm_forC4_logical(i,1)= (abs(cm_forC4(i,1)- Pressure_selection(1,1))+ abs(cm_forC4(i,4)- Pressure_selection(1,4)))< (meandiff_LSHD_forC4 - SDdiff_highdia_cm_forC4)/4;
     end
     cm_forC5 = cm_forC4(cm_forC4_logical, :);
 end
 
 
 for i = 1:size(cm_forC5,1)
     cm_forC5_logical(i,1) = cm_forC5(i,5)<cm_forC5(i,6);
 end
 
 cm_forC6 = cm_forC5(cm_forC5_logical, :);
 for i = 1:size(cm_forC6,1)
     for j = 3:4 
         diffcm_forC6(i,j)= cm_forC6(i,j)- min(Pressure_selection(1:2,j));
     end
     diffcm_forC6(i,5)= sum(abs(diffcm_forC6(i, 1:4))); %differences of lowsys and highdia
 end
 
 [~,rIcm_forC6] = min(diffcm_forC6(i,5));
 Central_newout = cm_forC6(rIcm_forC6,:);
 end
