% This file implements the Nitsche method to join two non-matching meshes.
% Non-matching meshes version. NURBS elements.
% Non hierarchical meshes. A background coarse mesh overlapped by a fine
% mesh.
%
% Timoshenko beam.
%
% Vinh Phu Nguyen
% Cardiff University, UK
% 13 July 2013

addpath ../../gmshFiles/
addpath ../../post-processing/
addpath ../../fem-functions/
addpath ../../analytical-solutions/
addpath ../../fem_util/;
addpath ../../nurbs-geopdes/inst/
addpath ../../nurbs-util/
addpath ../../meshing/
addpath ../../fem-functions/
addpath ../../post-processing/
addpath ../../xiga/
addpath ../../nurbs-geopdes/inst/
addpath ../../delamination/
addpath ../../xml_toolbox/
addpath ../../C_files/

clear all
colordef white
state = 0;
tic;

opts = struct('Color','rgb','Bounds','tight','FontMode','fixed','FontSize',20);
exportfig(gcf,'splinecurve.eps',opts)

% penalty (reguralisation) parameter

alpha = 1e9;

symmetric = 1;

if (symmetric)
    %Symmetric Nitsche method
    gamma1 = 1;
    gamma2 = 1;
else
    %Non-Symmetric Nitsche method
    gamma1 = -1;
    gamma2 = 0;
end

%% MATERIAL PROPERTIES-----------------------------------------------------
E0  = 3e7;  % Young?s modulus
nu0 = 0.3;  % Poisson?s ratio

% BEAM PROPERTIES
L  = 48;     % length of the beam
W  = 6;
c  = W/2;

L1=25;


% TIP LOAD
P = 1000; % the peak magnitude of the traction at the right edge
I0=2*c^3/3;  % the second polar moment of inertia of the beam cross-section.

% COMPUTE ELASTICITY MATRIX
C=E0/(1-nu0^2)*[   1      nu0          0;
    nu0        1          0;
    0        0  (1-nu0)/2 ];

material.stiffMat=C;

%% MESHING

%% mesh1 ------------------------------------------------------------------
% fine mesh only from left boundary to L1

controlPts          = zeros(4,2,2);

controlPts(1:2,1,1) = [0;-c];
controlPts(1:2,2,1) = [L1;-c];
controlPts(1:2,1,2) = [0;c];
controlPts(1:2,2,2) = [L1;c];

controlPts(4,:,:)   = 1;

uKnot = [0 0 1 1];
vKnot = [0 0 1 1];

solid1 = nrbmak(controlPts,{uKnot vKnot});

% evaluate order

solid1 = nrbdegelev(solid1,[2 2]);

uKnot     = cell2mat(solid1.knots(1));
vKnot     = cell2mat(solid1.knots(2));

solid1     = nrbkntins(solid1,{[] [0.3 0.7]});

refineCountX = 3;
for i=1:refineCountX
    uKnotVectorU = unique(uKnot);
    uKnotVectorV = unique(vKnot);
    newKnotsX = uKnotVectorU(1:end-1) + 0.5*diff(uKnotVectorU);
    newKnotsY = uKnotVectorV(1:end-1) + 0.5*diff(uKnotVectorV);
    newKnots  = {newKnotsX []};
    solid1     = nrbkntins(solid1,newKnots);
    uKnot      = cell2mat(solid1.knots(1));
    vKnot      = cell2mat(solid1.knots(2));
end

refineCountX = 1;
for i=1:refineCountX
    uKnotVectorU = unique(uKnot);
    uKnotVectorV = unique(vKnot);
    newKnotsX = uKnotVectorU(1:end-1) + 0.5*diff(uKnotVectorU);
    newKnotsY = uKnotVectorV(1:end-1) + 0.5*diff(uKnotVectorV);
    newKnots  = {[] newKnotsY};
    solid1     = nrbkntins(solid1,newKnots);
    uKnot      = cell2mat(solid1.knots(1));
    vKnot      = cell2mat(solid1.knots(2));
end

mesh1 = buildIGA2DMesh (solid1);

%% mesh2-------------------------------------------------------------------
% mesh2= coarse background mesh for the entire domain

controlPts          = zeros(4,2,2);

controlPts(1:2,1,1) = [0;-c];
controlPts(1:2,2,1) = [L;-c];
controlPts(1:2,1,2) = [0;c];
controlPts(1:2,2,2) = [L;c];

controlPts(4,:,:)   = 1;

uKnot = [0 0 1 1];
vKnot = [0 0 1 1];

solid2 = nrbmak(controlPts,{uKnot vKnot});

% evaluate order

solid2 = nrbdegelev(solid2,[1 1]);

uKnot     = cell2mat(solid2.knots(1));
vKnot     = cell2mat(solid2.knots(2));

refineCountX = 2;
for i=1:refineCountX
    uKnotVectorU = unique(uKnot);
    uKnotVectorV = unique(vKnot);
    newKnotsY = [];
    newKnotsX = uKnotVectorU(1:end-1) + 0.5*diff(uKnotVectorU);
    newKnotsY = uKnotVectorV(1:end-1) + 0.5*diff(uKnotVectorV);
    newKnots  = {newKnotsX newKnotsY};
    solid2     = nrbkntins(solid2,newKnots);
    uKnot      = cell2mat(solid2.knots(1));
    vKnot      = cell2mat(solid2.knots(2));
end

% refineCountX = 1;
% for i=1:refineCountX
%     uKnotVectorU = unique(uKnot);
%     uKnotVectorV = unique(vKnot);
%     newKnotsY = [];
%     newKnotsX = uKnotVectorU(1:end-1) + 0.5*diff(uKnotVectorU);
%     newKnotsY = uKnotVectorV(1:end-1) + 0.5*diff(uKnotVectorV);
%     newKnots  = {newKnotsX []};
%     solid2     = nrbkntins(solid2,newKnots);
%     uKnot      = cell2mat(solid2.knots(1));
%     vKnot      = cell2mat(solid2.knots(2));
% end

mesh2 = buildIGA2DMesh (solid2);
mesh2.globElems = mesh2.globElems + size(mesh1.controlPts,1);

%% plot meshes

figure
hold on
nrbkntplot(solid1);
nrbkntplot(solid2);
plot(mesh1.controlPts(:,1),mesh1.controlPts(:,2),'o','MarkerEdgeColor','k',...
    'MarkerFaceColor','g','MarkerSize',6.5);
plot(mesh2.controlPts(:,1),mesh2.controlPts(:,2),'o','MarkerEdgeColor','k',...
    'MarkerFaceColor','w','MarkerSize',6.5);
axis off

%% combine two patches into one data structure

matMap1 = ones(mesh1.elemCount,1);
matMap2 = ones(mesh2.elemCount,1);

vMesh1=buildVisualizationMesh2D(solid1);
vMesh2=buildVisualizationMesh2D(solid2);

meshes{1}  = mesh1;
meshes{2}  = mesh2;
vmeshes{1} = vMesh1;
vmeshes{2} = vMesh2;


meshData.mesh    = meshes;
meshData.vmesh   = vmeshes;
meshData.matMap{1}=matMap1;
meshData.matMap{2}=matMap2;
materials{1}      = material;

%% determine cut elements, void elememnts and standard elements------------

vMesh=buildVisualizationMesh2D(solid2);
linInterfaceGeo   = [L1 0; L1 W];

% Compute level sets

nNode = size(vMesh.node,1);
chi   = zeros(1,nNode);


x0   = linInterfaceGeo(1,1); y0 = linInterfaceGeo(1,2);
x1   = linInterfaceGeo(2,1); y1 = linInterfaceGeo(2,2);

for i = 1 : nNode
    x                  = vMesh.node(i,1);
    y                  = vMesh.node(i,2);    
    phi                = x - x0;
    chi(1,i) = phi;
end

elem2State = zeros(mesh2.elemCount,1);

% loop over elements

for iel = 1 : mesh2.elemCount    
    sctrV   = vMesh.element(iel,:);
        
    phi  = chi(1,sctrV);
        
    if     ( max(phi)*min(phi) < 0 )
        elem2State(iel) = 1;             % cut elements
    elseif ( max(phi) < 0 )  
        elem2State(iel) = 0;             % void elements   
    else
        elem2State(iel) = 2;             % normal elements 
    end
end

% find inactive plate dofs

inactiveNodes1 = [];
inactiveNodes2 = [];

for i=1:mesh2.elemCount 
    sctr = mesh2.locElems(i,:);
    if     elem2State(i) == 0
        inactiveNodes1 = [inactiveNodes1;sctr];
    elseif elem2State(i) == 1
        inactiveNodes2 = [inactiveNodes2;sctr];
    end
end

inactiveNodes1 = unique(inactiveNodes1);
inactiveNodes2 = unique(inactiveNodes2);

inactiveNodes = setdiff(inactiveNodes1,inactiveNodes2);
inactiveNodes = inactiveNodes + size(mesh1.controlPts,1);

%% boundary mesh for domain 1
bndMesh1 = [];
for i=1:mesh1.noElemsV
    bndMesh1 = [bndMesh1; mesh1.noElemsU*i ];
end

bndMesh2 = find(elem2State==1);

% boundary edges

bndNodes  = find(abs(mesh1.controlPts(:,1)-L1)<1e-14);
bndEdge1  = zeros(mesh1.noElemsV,mesh1.q+1);

for i=1:mesh1.noElemsV
    bndEdge1(i,:) = bndNodes(i:i+mesh1.q);
end


%% determine GPs (for mesh1 and mesh2) on coupling interface

ngp = (mesh1.p+1)*(mesh1.q+1);

[W1,Q1]=quadrature( 9, 'GAUSS', 1 ); % two point quadrature

xgp1 = [];
xgp2 = [];
Xgp = [];
wgt = [];
normal=[];
elems1=[];
elems2=[];

for e=1:mesh1.noElemsV
    sctrEdge = bndEdge1(e,:);
    sctr1    = mesh1.globElems(bndMesh1(e),:);
    pts1     = mesh1.controlPts(sctr1,:);
    xiE1     = mesh1.rangeU(end,:); % [xi_i,xi_i+1]
    etE1     = mesh1.rangeV(e,:);   % [et_j,eta_j+1]
    for q=1:size(W1)
        pt=Q1(q,:);
        wt=W1(q);
        Xi      = 0.5 * ( ( etE1(2) - etE1(1) ) * pt + etE1(2) + etE1(1));
        J2      = 0.5 * ( etE1(2) - etE1(1) );
        [N dNdxi] = NURBS1DBasisDers(Xi,mesh1.q,mesh1.vKnot,mesh1.weights);
        J0=dNdxi*mesh1.controlPts(sctrEdge,:); % also the tangent to Gamma_*^e
        detJ0=norm(J0);
        J0 = J0/detJ0;
        
        x=N*mesh1.controlPts(sctrEdge,:);
        knotSpanIndex = FindSpan(mesh2.noPtsY-1,mesh2.q,Xi,mesh2.vKnot);
        
        X1 = global2LocalMapNURBS2D(x,pts1,xiE1,etE1,mesh1.p,mesh1.q, ...
            mesh1.uKnot, mesh1.vKnot, mesh1.weights);
        
        Xgp    = [Xgp;x];
        xgp1   = [xgp1;X1];
        wgt    = [wgt;wt*detJ0*J2];
        normal = [normal;-J0(2) J0(1)];
        elems2 = [elems2;bndMesh2(knotSpanIndex-mesh2.q+1)];
        elems1 = [elems1;bndMesh1(e)];
    end
end

for i=1:length(Xgp)
    x = Xgp(i,:);
    e = elems2(i);
    idu    = mesh2.index(e,1);
    idv    = mesh2.index(e,2);
    sctr2    = mesh2.locElems(e,:);
    pts2     = mesh2.controlPts(sctr2,:);
    xiE2     = mesh2.rangeU(idu,:); % [xi_i,xi_i+1]
    etE2     = mesh2.rangeV(idv,:);   % [et_j,eta_j+1]
    X2 = global2LocalMapNURBS2D(x,pts2,xiE2,etE2,mesh2.p,mesh2.q, ...
                                mesh2.uKnot, mesh2.vKnot, mesh2.weights);
    xgp2 = [xgp2;X2];
end

% DEFINE BOUNDARIES

% GET NODES ON DISPLACEMENT BOUNDARY
%      Here we get the nodes on the essential boundaries

fixedNode=find(mesh1.controlPts(:,1)==0);
rightNode=find(mesh2.controlPts(:,1)==L);

rightEdge   = zeros(mesh2.noElemsV,mesh2.q+1);

for i=1:mesh2.noElemsV
    rightEdge(i,:) = rightNode(i:i+mesh2.q);
end

numnodes = size(mesh1.controlPts,1) + size(mesh2.controlPts,1);

%% least square for boujndary conditions

dispNodes   = fixedNode;
noDispNodes = length(dispNodes);


bndElement     = zeros(mesh1.noElemsV,mesh1.q+1); % assume p=q!!!
leftEdgeMesh   = zeros(mesh1.noElemsV,mesh1.q+1);

for i=1:mesh1.noElemsV
    leftEdgeMesh(i,:)  = fixedNode (i:i+mesh1.q);
end

% build boundary mesh for assembly matrix A in Aq=b

for ie=1:mesh1.noElemsV
    bndElement(ie,:) = [ie:ie+mesh1.q];
end

% essential boundary conditions, exact displacement is used
% on the boundary edges

disp([num2str(toc),'  LEAST SQUARE for DIRICHLET BCs'])

A  = zeros(noDispNodes,noDispNodes);
bx = zeros(noDispNodes,1);
by = zeros(noDispNodes,1);

noxC   = 8;

% Loop over boundary edges...
% left edge

for ie=1:mesh1.noElemsV
    sctr   = leftEdgeMesh(ie,:);
    pts    = mesh1.controlPts(sctr,:);
    sctrA  = bndElement(ie,:);
    xiE    = mesh1.rangeV(ie,:);
    xiArr  = linspace(xiE(1),xiE(2),noxC);
    
    for ic=1:noxC
        xi = xiArr(ic);
        [N dNdxi] = NURBS1DBasisDers(xi,mesh1.q,mesh1.vKnot,mesh1.weights);
        
        A(sctrA,sctrA) = A(sctrA,sctrA) + N'*N;
        
        pt        = N    *pts;
        
        x = pt(1); y = pt(2);
        
        % exact displacements
        
        ux = P*y/(6*E0*I0)*((6*L-3*x)*x+(2+nu0)*(y^2-W^2/4));
        uy = -P/(6*E0*I0)*(3*nu0*y^2*(L-x)+(4+5*nu0)*W^2*x/4+(3*L-x)*x^2);
        
        bx(sctrA) = bx(sctrA) + ux*N';
        by(sctrA) = by(sctrA) + uy*N';
    end
end

% solve the system Aq_x=bx and Aq_y=by

[LL UU] = lu(A);
qxTemp  = LL\bx;
qyTemp  = LL\by;
qx      = UU\qxTemp;
qy      = UU\qyTemp;

%%%%

uFixed     = qx;
vFixed     = qy;

fixedNode = [fixedNode;inactiveNodes];

uFixed = [uFixed;zeros(length(inactiveNodes),1)];
vFixed = [vFixed;zeros(length(inactiveNodes),1)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE SYSTEM DATA STRUCTURES

disp([num2str(toc),' INITIALIZING DATA STRUCTURES'])

f=zeros(2*numnodes,1);          % external load vector
K=zeros(2*numnodes,2*numnodes); % stiffness matrix

% ******************************************************************************
% ***                          P R O C E S S I N G                           ***
% ******************************************************************************
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% COMPUTE STIFFNESS MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp([num2str(toc),'   COMPUTING STIFFNESS MATRIX'])

%% domain integrals--------------------------------------------------------

for ip=1:length(meshes)
    mesh = meshes{ip};
    [W,Q]= quadrature( mesh.p+1, 'GAUSS', 2 ); % 2x2 Gaussian quadrature
    
    for e=1:mesh.elemCount
        % skip void elements
        if (ip ==2 && elem2State(e) == 0)
            continue
        end
        idu    = mesh.index(e,1);
        idv    = mesh.index(e,2);
        xiE    = mesh.rangeU(idu,:); % [xi_i,xi_i+1]
        etaE   = mesh.rangeV(idv,:); % [eta_j,eta_j+1]
        
        sctrg  = mesh.globElems(e,:);         %  element scatter vector
        sctrl  = mesh.locElems (e,:);         %  element scatter vector
        nn     = length(sctrg);
        sctrB  = zeros(1,2*nn);
        sctrB(1,1:2:2*nn) = 2*sctrg-1;
        sctrB(1,2:2:2*nn) = 2*sctrg  ;
        
        pts    = mesh.controlPts(sctrl,:);
        
        % cut element, special integration rule
        if (ip ==2 && elem2State(e) == 1 )
            [W,Q]=quadrature(  (mesh.p+1)*3, 'GAUSS', 2 ); % 2 x2point quadrature
            x=zeros(size(W,1),1);
            for gp=1:size(W,1)
                pt      = Q(gp,:);
                Xi      = parent2ParametricSpace(xiE,  pt(1));
                Eta     = parent2ParametricSpace(etaE, pt(2));
                [R dRdxi dRdeta ] = ...
                    NURBS2DBasisDers([Xi; Eta],mesh.p,mesh.q,mesh.uKnot,mesh.vKnot,mesh.weights');
                x = R*pts(:,1);
            end
            id = find(x<L1);
            W(id)=[];
            Q(id)=[];
        end
        
        % loop over Gauss points
        for gp=1:size(W,1)
            pt      = Q(gp,:);
            wt      = W(gp);
            Xi      = parent2ParametricSpace(xiE,pt(1));
            Eta     = parent2ParametricSpace(etaE,pt(2));
            J2      = jacobianPaPaMapping(xiE,etaE);
            
            % compute derivatives of shape functions
            [R dRdxi dRdeta] = NURBS2DBasisDers([Xi; Eta],mesh.p,mesh.q,mesh.uKnot,mesh.vKnot,mesh.weights');
            
            % compute the jacobian of physical and parameter domain mapping
            % then the derivative w.r.t spatial physical coordinates
            
            jacob      =  pts' * [dRdxi' dRdeta'];
            J1         = det(jacob);
            invJacob   = inv(jacob);
            dRdx       = [dRdxi' dRdeta'] * invJacob;
            J          = J1 * J2;
            B           = getBmatrix2D(dRdx');
            K(sctrB,sctrB) = K(sctrB,sctrB) + B' * C * B * J * wt;
        end
    end
end

%% interface integrals-----------------------------------------------------

for i=1:length(wgt)                     % start of element loop
    e1     = elems1(i);
    e2     = elems2(i);
    sctr1  = mesh1.globElems(e1,:);
    sctr2  = mesh2.globElems(e2,:);
    sctr2L = mesh2.locElems (e2,:);
    
    nn1 = length(sctr1);
    nn2 = length(sctr2);
    
    sctrB1(1,1:2:2*nn1) = 2*sctr1-1;
    sctrB1(1,2:2:2*nn1) = 2*sctr1  ;
    
    sctrB2(1,1:2:2*nn2) = 2*sctr2-1;
    sctrB2(1,2:2:2*nn2) = 2*sctr2  ;
    
    pts1 = mesh1.controlPts(sctr1,:);
    pts2 = mesh2.controlPts(sctr2L,:);
    
    idv1      = mesh1.index(e1,2);
    idv2      = mesh2.index(e2,2);
    xiE1      = mesh1.rangeU(end,:); % [xi_i,xi_i+1]
    etE1      = mesh1.rangeV(idv1,:);   % [et_j,eta_j+1]
    xiE2      = mesh2.rangeU(1,:); % [xi_i,xi_i+1]
    etE2      = mesh2.rangeV(idv2,:);   % [et_j,eta_j+1]
    
    pt1 = xgp1(i,1:2);
    pt2 = xgp2(i,1:2);
    wt1 = wgt(i);
    
    normalv=normal(i,:);
    n = [normalv(1) 0 normalv(2);0 normalv(2) normalv(1)];
    n = -n;
    
    % compute derivatives of shape functions
    [R1 dR1dxi dR1deta] = NURBS2DBasisDers(pt1,mesh1.p,mesh1.q,mesh1.uKnot,mesh1.vKnot,mesh1.weights');
    [R2 dR2dxi dR2deta] = NURBS2DBasisDers(pt2,mesh2.p,mesh2.q,mesh2.uKnot,mesh2.vKnot,mesh2.weights');
    
    % compute the jacobian of physical and parameter domain mapping
    % then the derivative w.r.t spatial physical coordinates
    
    jacob1     = [dR1dxi; dR1deta] * pts1;
    jacob2     = [dR2dxi; dR2deta] * pts2;
    invJacob1   = inv(jacob1);
    invJacob2   = inv(jacob2);
    dR1dx      = [dR1dxi' dR1deta'] * invJacob1;
    dR2dx      = [dR2dxi' dR2deta'] * invJacob2;
    
    
    B1(1,1:2:nn1*2)  = dR1dx(:,1)';
    B1(2,2:2:nn1*2)  = dR1dx(:,2)';
    B1(3,1:2:nn1*2)  = dR1dx(:,2)';
    B1(3,2:2:nn1*2)  = dR1dx(:,1)';
    
    B2(1,1:2:nn2*2)  = dR2dx(:,1)';
    B2(2,2:2:nn2*2)  = dR2dx(:,2)';
    B2(3,1:2:nn2*2)  = dR2dx(:,2)';
    B2(3,2:2:nn2*2)  = dR2dx(:,1)';
    
    Nm1(1,1:2:nn1*2)  = R1';
    Nm1(2,2:2:nn1*2)  = R1';
    Nm2(1,1:2:nn2*2)  = R2';
    Nm2(2,2:2:nn2*2)  = R2';
    
    % COMPUTE ELEMENT STIFFNESS AT QUADRATURE POINT
    
    Kp11 = alpha*(Nm1'*Nm1)*wt1;
    Kp12 = alpha*(Nm1'*Nm2)*wt1;
    Kp22 = alpha*(Nm2'*Nm2)*wt1;
    
    Kd11 = 0.5 * Nm1'* n * C * B1 *wt1;
    Kd12 = 0.5 * Nm1'* n * C * B2 *wt1;
    Kd21 = 0.5 * Nm2'* n * C * B1 *wt1;
    Kd22 = 0.5 * Nm2'* n * C * B2 *wt1;
    

    K(sctrB1,sctrB1)  = K(sctrB1,sctrB1)  - Kd11 - gamma1*Kd11' + gamma2*Kp11;
    K(sctrB1,sctrB2)  = K(sctrB1,sctrB2)  - Kd12 + gamma1*Kd21' - gamma2*Kp12;
    K(sctrB2,sctrB1)  = K(sctrB2,sctrB1)  + Kd21 - gamma1*Kd12' - gamma2*Kp12';
    K(sctrB2,sctrB2)  = K(sctrB2,sctrB2)  + Kd22 + gamma1*Kd22' + gamma2*Kp22;
end



%% External force

[W,Q]=quadrature( 9, 'GAUSS', 1 ); % three point quadrature

for e=1:mesh2.noElemsV
    xiE   = mesh2.rangeV(e,:); % [xi_i,xi_i+1]
    conn  = rightEdge(e,:);
    pts   = mesh2.controlPts(conn,:);
    sctr  = rightEdge(e,:) + size(mesh1.controlPts,1);
    sctrx = 2*sctr-1;
    sctry = 2*sctr;
    
    % loop over Gauss points
    for gp=1:size(W1,1)
        xi      = Q1(gp,:);
        wt      = W1(gp);
        Xi      = 0.5 * ( ( xiE(2) - xiE(1) ) * xi + xiE(2) + xiE(1));
        J2      = 0.5 * ( xiE(2) - xiE(1) );
        
        [N dNdxi] = NURBS1DBasisDers(Xi,mesh2.q,mesh2.vKnot,mesh2.weights);
        
        % compute the jacobian of physical and parameter domain mapping
        % then the derivative w.r.t spatial physical coordinates
        
        x        = N     * pts; % global coord of GP
        jacob1   = dNdxi * pts;
        J1       = norm (jacob1);
        fac = J1 * J2 * wt;
        yPt=N*mesh2.controlPts(rightEdge(e,:),2);
        fyPt=-P*(c^2-yPt^2)/(2*I0);
        f(sctry) = f(sctry) + N' * fyPt * fac;
    end
end


%%%%%%%%%%%%%%%%%%% END OF STIFFNESS MATRIX COMPUTATION %%%%%%%%%%%%%%%%%%%


% APPLY ESSENTIAL BOUNDARY CONDITIONS
disp([num2str(toc),'   APPLYING BOUNDARY CONDITIONS'])
bcwt=mean(diag(K)); % a measure of the average size of an element in K
% used to keep the conditioning of the K matrix
udofs=2*fixedNode-1;           % global indecies of the fixed x displacements
vdofs=2*fixedNode;   % global indecies of the fixed y displacements
f=f-K(:,udofs)*uFixed;  % modify the force vector
f=f-K(:,vdofs)*vFixed;
K(udofs,:)=0;
K(vdofs,:)=0;
K(:,udofs)=0;
K(:,vdofs)=0;
K(udofs,udofs)=bcwt*speye(length(udofs)); % put ones*bcwt on the diagonal
K(vdofs,vdofs)=bcwt*speye(length(vdofs));
f(udofs)=bcwt*speye(length(udofs))*uFixed;
f(vdofs)=bcwt*speye(length(udofs))*vFixed;

% SOLVE SYSTEM
disp([num2str(toc),'   SOLVING SYSTEM'])
U=K\f;

%******************************************************************************
%*** POST - PROCESSING ***
%***************************************************

disp([num2str(toc),'   POST-PROCESSING'])

%%

%%

id1=1:size(mesh1.controlPts,1);
id2=[1:size(mesh2.controlPts,1)] + size(mesh1.controlPts,1);

Ux1 = U(2*id1-1);
Uy1 = U(2*id1  );
Ux2 = U(2*id2-1);
Uy2 = U(2*id2  );

factor=100;
ctrpts1 = reshape(solid1.coefs,4,[]).';
ctrpts1(:,[1 2]) = ctrpts1(:,[1 2]) + factor*[Ux1 Uy1];
ctrpts1 = reshape(ctrpts1.', 4, solid1.number(1), solid1.number(2));
solid1 = nrbmak(ctrpts1,{solid1.knots{1} solid1.knots{2}});

ctrpts2 = reshape(solid2.coefs,4,[]).';
ctrpts2(:,[1 2]) = ctrpts2(:,[1 2]) + factor*[Ux2 Uy2];
ctrpts2 = reshape(ctrpts2.', 4, solid2.number(1),solid2.number(2));
solid2  = nrbmak(ctrpts2,{solid2.knots{1} solid2.knots{2}});

figure
hold on
nrbkntplot(solid1);
nrbkntplot(solid2);
view(0,90);

%% write to Paraview
displacement = [U(1:2:end) U(2:2:end)];


vtuFileName = 'iga-nitsche-tbeam-embed';
for ip=1:2
    vtuFile = strcat(vtuFileName,'-mesh',num2str(ip));
    %figure; hold on;
    ok      = plotStress2DForPatch(meshData,ip,vtuFile,displacement,materials);
end

pvdFile = fopen(strcat(vtuFileName,'.pvd'), 'wt');

fprintf(pvdFile,'<VTKFile byte_order="LittleEndian" type="Collection" version="0.1">\n');
fprintf(pvdFile,'<Collection>\n');


for im=1:length(meshes)
    vtuFile = sprintf('%s%s%d%s',vtuFileName,'-mesh',im,'.vtu');
    fprintf(pvdFile,'<DataSet file=''%s'' groups='''' part=''%d'' timestep=''%d''/>\n',...
        vtuFile,im,1);
end


fprintf(pvdFile,'</Collection>\n');
fprintf(pvdFile,'</VTKFile>\n');

fclose(pvdFile);
%%

aa=4;
elems1 = mesh1.noElemsU*aa+1:mesh1.noElemsU*(aa+1);
sigma      = zeros(length(elems1),2);
sigmaRef   = zeros(length(elems1),2);
xcoord     = zeros(length(elems1),2);

for e=1:length(elems1)
    ie = elems1(e);
    idu    = mesh1.index(ie,1);
    idv    = mesh1.index(ie,2);
    xiE    = mesh1.rangeU(idu,:); % [xi_i,xi_i+1]
    etaE   = mesh1.rangeV(idv,:); % [eta_j,eta_j+1]
    
    sctr   = mesh1.globElems(ie,:);         %  element scatter vector
    nn     = length(sctr);
    
    sctrB(1,1:2:2*nn) = 2*sctr-1;
    sctrB(1,2:2:2*nn) = 2*sctr  ;
    
    pts    = mesh1.controlPts(sctr,:);
    
    % loop over Gauss points
    
    %for gp=1:size(W,1)
    pt      = [0 0];
    Xi      = parent2ParametricSpace(xiE,pt(1));
    Eta     = parent2ParametricSpace(etaE,pt(2));
    J2      = jacobianPaPaMapping(xiE,etaE);
    
    % compute derivatives of shape functions
    [R dRdxi dRdeta] = NURBS2DBasisDers([Xi; Eta],mesh1.p,mesh1.q,mesh1.uKnot,mesh1.vKnot,mesh1.weights');
    
    % compute the jacobian of physical and parameter domain mapping
    % then the derivative w.r.t spatial physical coordinates
    
    jacob      =  pts' * [dRdxi' dRdeta'];
    invJacob   = inv(jacob);
    dRdx       = [dRdxi' dRdeta'] * invJacob;
    yPt=R*pts;
    B           = getBmatrix2D(dRdx');
    % COMPUTE ELEMENT STRAIN AND STRESS AT STRESS POINT
    strain=B*U(sctrB);
    stress=C*strain;
    sigma(e,1)    = stress(1);
    sigma(e,2)    = stress(3);
    sigmaRef(e,1) = 1000/I0*(L-yPt(1))*yPt(2);
    sigmaRef(e,2) = -1000/2/I0*(c^2-yPt(2)^2);
    xcoord(e,:)     = yPt;
end   % of element loop

colordef white
figure,set (gcf,'Color','w')
set(gca,'FontSize',14)
hold on
plot(xcoord(:,1),sigmaRef(:,1),'k-','LineWidth',1.4);
plot(xcoord(:,1),sigma(:,1),'o','MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',6.5);
plot(xcoord(:,1),sigmaRef(:,2),'k-','LineWidth',1.4);
plot(xcoord(:,1),sigma(:,2),'s','MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',6.5);
h=legend('sigmaxx-exact','sigmaxx-coupling','sigmaxy-exact','sigmaxy-coupling');
xlabel('x')
ylabel('stresses at y=0.75')
grid on

%%

aa=8;
elems1 = aa:mesh1.noElemsU:aa+mesh1.noElemsU*(mesh1.noElemsV-1);

sigma      = zeros(length(elems1),2);
sigmaRef   = zeros(length(elems1),2);
xcoord     = zeros(length(elems1),2);

for e=1:length(elems1)
    ie = elems1(e);
    idu    = mesh1.index(ie,1);
    idv    = mesh1.index(ie,2);
    xiE    = mesh1.rangeU(idu,:); % [xi_i,xi_i+1]
    etaE   = mesh1.rangeV(idv,:); % [eta_j,eta_j+1]
    
    sctr   = mesh1.globElems(ie,:);         %  element scatter vector
    nn     = length(sctr);
    
    sctrB(1,1:2:2*nn) = 2*sctr-1;
    sctrB(1,2:2:2*nn) = 2*sctr  ;
    
    pts    = mesh1.controlPts(sctr,:);
    
    % loop over Gauss points
    
    %for gp=1:size(W,1)
    pt      = [1 0];
    Xi      = parent2ParametricSpace(xiE,pt(1));
    Eta     = parent2ParametricSpace(etaE,pt(2));
    J2      = jacobianPaPaMapping(xiE,etaE);
    
    % compute derivatives of shape functions
    [R dRdxi dRdeta] = NURBS2DBasisDers([Xi; Eta],mesh1.p,mesh1.q,mesh1.uKnot,mesh1.vKnot,mesh1.weights');
    
    % compute the jacobian of physical and parameter domain mapping
    % then the derivative w.r.t spatial physical coordinates
    
    jacob      =  pts' * [dRdxi' dRdeta'];
    invJacob   = inv(jacob);
    dRdx       = [dRdxi' dRdeta'] * invJacob;
    yPt=R*pts;
    B           = getBmatrix2D(dRdx');
    % COMPUTE ELEMENT STRAIN AND STRESS AT STRESS POINT
    strain=B*U(sctrB);
    stress=C*strain;
    sigma(e,1)    = stress(1);
    sigma(e,2)    = stress(3);
    sigmaRef(e,1) = 1000/I0*(L-yPt(1))*yPt(2);
    sigmaRef(e,2) = -1000/2/I0*(c^2-yPt(2)^2);
    xcoord(e,:)     = yPt;
end   % of element loop

colordef white
figure,set (gcf,'Color','w')
set(gca,'FontSize',14)
hold on
plot(xcoord(:,2),sigmaRef(:,2),'k-','LineWidth',1.4);
plot(xcoord(:,2),sigma(:,2),'o','MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize',6.5);
% plot(xcoord(:,2),sigmaRef(:,2),'k-','LineWidth',1.4);
% plot(xcoord(:,2),sigma(:,2),'s','MarkerEdgeColor','k',...
%     'MarkerFaceColor','g',...
%     'MarkerSize',6.5);
h=legend('sigmaxy-exact','sigmaxy-coupling');
xlabel('y')
ylabel('sigma_{xy} at x=L/2')
grid on