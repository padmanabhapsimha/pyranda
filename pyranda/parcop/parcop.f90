!===================================================================================================
! Copyright (c) 2018, Lawrence Livemore National Security, LLC.
! Produced at the Lawrence Livermore National Laboratory.
!
! LLNL-CODE-749864
! This file is part of pyranda
! For details about use and distribution, please read: pyranda/LICENSE
!
! Written by: Britton J. Olson, olson45@llnl.gov
!===================================================================================================
MODULE parcop

  USE LES_objects
  USE LES_comm, ONLY : LES_comm_world
  USE LES_compact_operators, ONLY : d1x, d1y, d1z
  USE LES_operators, ONLY : div,grad,Laplacian
  USE LES_operators, ONLY : curl,cross,filter,ring

  CONTAINS


    SUBROUTINE setup(patch,level,COMM, &
         & nx,ny,nz,px,py,pz,coordsys, &
         & x1,xn,y1,yn,z1,zn,bx1,bxn,by1,byn,bz1,bzn)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: patch,level
      INTEGER,               INTENT(IN) :: COMM
      INTEGER,               INTENT(IN) :: nx,ny,nz,px,py,pz
      INTEGER,               INTENT(IN) :: coordsys
      REAL(kind=8),   INTENT(IN)   :: x1,xn,y1,yn,z1,zn
      CHARACTER(LEN=*), INTENT(IN) :: bx1,bxn,by1,byn,bz1,bzn
      
      REAL(kind=8)                 :: x1f,xnf,y1f,ynf,z1f,znf
      INTEGER                      :: color,key
      REAL(kind=8)                 :: simtime
      REAL(kind=8)                 :: dx,dy,dz
      

      color = 0
      key = 0
      simtime = 0.0D0

      LES_comm_world = COMM

      ! Convert to faces
      dx = (xn-x1) / DBLE( MAX(nx-1,1) )
      dy = (yn-y1) / DBLE( MAX(ny-1,1) )
      dz = (zn-z1) / DBLE( MAX(nz-1,1) )

      x1f = x1 - dx/2.0D0
      xnf = xn + dx/2.0D0
      y1f = y1 - dy/2.0D0
      ynf = yn + dy/2.0D0
      z1f = z1 - dz/2.0D0
      znf = zn + dz/2.0D0
      
      CALL setup_objects(patch,level,color,key,coordsys,nx,ny,nz,px,py,pz,x1f,xnf,y1f,ynf,z1f,znf,bx1,bxn,by1,byn,bz1,bzn,simtime)
      
      
    END SUBROUTINE setup


    SUBROUTINE setup_mesh(patch,level)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: patch,level

      CALL setup_mesh_data(patch,level)
      
    END SUBROUTINE setup_mesh


    SUBROUTINE setup_mesh_x3(patch,level,x1,x2,x3)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: patch,level
      REAL(kind=8), DIMENSION(:,:,:), INTENT(IN) :: x1,x2,x3
      
      CALL setup_mesh_data_x3(patch,level,x1,x2,x3)
      
    END SUBROUTINE setup_mesh_x3

     
    SUBROUTINE xGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg
      
      dxg = mesh_ptr%xgrid      
    END SUBROUTINE xGrid

    SUBROUTINE yGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg      

      dxg = mesh_ptr%ygrid      
    END SUBROUTINE yGrid

    SUBROUTINE zGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg      

      dxg = mesh_ptr%zgrid      
    END SUBROUTINE zGrid

        SUBROUTINE dxGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg
      
      dxg = mesh_ptr%d1     
    END SUBROUTINE dxGrid

    SUBROUTINE dyGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg      

      dxg = mesh_ptr%d2     
    END SUBROUTINE dyGrid

    SUBROUTINE dzGrid(dxg,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dxg      

      dxg = mesh_ptr%d3      
    END SUBROUTINE dzGrid


    SUBROUTINE mesh_getCellVol(CellVol,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      REAL(KIND=8), DIMENSION(nx,ny,nz),INTENT(out) :: CellVol
      CellVol = mesh_ptr%CellVol            
    END SUBROUTINE mesh_getCellVol

    SUBROUTINE mesh_getGridLen(GridLen,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      REAL(KIND=8), DIMENSION(nx,ny,nz),INTENT(out) :: GridLen
      GridLen = mesh_ptr%GridLen
    END SUBROUTINE mesh_getGridLen


    

    SUBROUTINE set_patch(patch,level)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: patch,level
      CALL point_to_objects(patch,level)
    END SUBROUTINE set_patch

    SUBROUTINE divergence(fx,fy,fz,val,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,    INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(in)  :: fx,fy,fz 
      real(kind=8), dimension(nx,ny,nz),intent(out) :: val

      CALL div(fx,fy,fz,val)
      
      
    END SUBROUTINE divergence
    
    SUBROUTINE ddx(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval      


      CALL d1x(val,dval)

    END SUBROUTINE ddx

    SUBROUTINE ddy(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      
      CALL d1y(val,dval)

    END SUBROUTINE ddy
    
    SUBROUTINE ddz(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      
      CALL d1z(val,dval)

    END SUBROUTINE ddz

    SUBROUTINE plaplacian(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      
      CALL Laplacian(val,dval)

    END SUBROUTINE plaplacian
   
    SUBROUTINE pRing(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      
      dval = ring( val )

    END SUBROUTINE pRing
 
    

    SUBROUTINE sFilter(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      CHARACTER(LEN=8), PARAMETER :: filtype='spectral'

      CALL filter(filtype,val,dval)

    END SUBROUTINE sFilter

    SUBROUTINE gFilter(val,dval,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz), intent(in) :: val
      real(kind=8), dimension(nx,ny,nz),intent(out) :: dval
      CHARACTER(LEN=6), PARAMETER :: filtype='smooth'

      CALL filter(filtype,val,dval)

    END SUBROUTINE gFilter


    SUBROUTINE gradS(val,val1,val2,val3,nx,ny,nz)
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: nx,ny,nz
      real(kind=8), dimension(nx,ny,nz),intent(in) :: val
      real(kind=8), dimension(nx,ny,nz), intent(out) :: val1,val2,val3
    
      CALL grad(val,val1,val2,val3)

    END SUBROUTINE gradS


   

 !! Communication objects from Python
    SUBROUTINE commFromPy( patch, level, comm_list )
      IMPLICIT NONE
      INTEGER,               INTENT(IN) :: patch,level
      INTEGER, DIMENSION(7), INTENT(IN) :: comm_list

      CALL point_to_objects(patch,level)
      
      comm_ptr%xyzcom = comm_list(1)
      comm_ptr%xycom  = comm_list(2)
      comm_ptr%xzcom  = comm_list(3)
      comm_ptr%yzcom  = comm_list(4)
      comm_ptr%xcom   = comm_list(5)
      comm_ptr%ycom   = comm_list(6)
      comm_ptr%zcom   = comm_list(7)
      
      ! Need to add _hi _lo comms for ghost data

      
    END SUBROUTINE commFromPy


    SUBROUTINE commx(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%xcom
    END SUBROUTINE commx

    SUBROUTINE commy(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%ycom
    END SUBROUTINE commy

    SUBROUTINE commz(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%zcom
    END SUBROUTINE commz

    SUBROUTINE commxy(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%xycom
    END SUBROUTINE commxy

    SUBROUTINE commxz(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%xzcom
    END SUBROUTINE commxz

    SUBROUTINE commyz(COMM)
      IMPLICIT NONE
      INTEGER,               INTENT(OUT) :: COMM      
      COMM = comm_ptr%yzcom
    END SUBROUTINE commyz


END MODULE parcop
