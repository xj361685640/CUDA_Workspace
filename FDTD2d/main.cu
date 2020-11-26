#define _USE_MATH_DEFINES
#include <iostream>
#include <cmath>
#include <fstream>
#include <string>
#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>

#include "main.h"

/*__global__ void add_Jz( int i_s, int j_s, float *Ez_d, float t, float Dt, float t0, float sigma );
__global__ void update_Ez( int Nx, int Ny, float* Ez_d, float* Hx_d, float* Hy_d, float Coeff_Ez1, float Coeff_Ez2 );
__global__ void update_Hx( int Nx, int Ny, float* Hx_d, float* Ez_d, float Coeff_Hx );
__global__ void update_Hy( int Nx, int Ny, float* Hy_d, float* Ez_d, float Coeff_Hy );*/

int main( void )
{
    /* Memory allocate (host) */
    float *Ez = new float[ ( Nx+1 )*( Ny+1 )];
    float *Hx = new float[ ( Nx+1 )*Ny ];
    float *Hy = new float[ Nx*( Ny+1 ) ];

    /* initialize */
    for( int i = 0; i < Nx+1; i++ ){
        for( int j = 0; j < Ny+1; j++ ) Ez[ idx_Ez(i, j) ] = 0.0;
    }

    for( int i = 0; i < Nx+1; i++ ){
        for( int j = 0; j < Ny; j++ ) Hx[ idx_Hx(i, j) ] = 0.0;
    }

    for( int i = 0; i < Nx; i++ ){
        for( int j = 0; j < Ny+1; j++ ) Hy[ idx_Hy(i, j) ] = 0.0;
    }

    /* Memory allocate (device) */
    float *Ez_d, *Hx_d, *Hy_d;
    cudaMalloc( (void**)&Ez_d, sizeof(float)*(Nx+1)*(Ny+1) );
    cudaMalloc( (void**)&Hx_d, sizeof(float)*(Nx+1)*Ny );
    cudaMalloc( (void**)&Hy_d, sizeof(float)*Nx*(Ny+1) );

    /* Copy Host to Device */
    cudaMemcpy( Ez_d, Ez, sizeof(float)*(Nx+1)*(Ny+1),  cudaMemcpyHostToDevice );
    cudaMemcpy( Hx_d, Hx, sizeof(float)*(Nx+1)*Ny,  cudaMemcpyHostToDevice );
    cudaMemcpy( Hy_d, Hy, sizeof(float)*Nx*(Ny+1),  cudaMemcpyHostToDevice );

    dim3 Dg(10,10,1), Db(10,10,1);

    int NT{ int(Tmax/Dt) };

    /*std::cout << i_s << " " << j_s << " " << Dt << " " << sig << " " << EPS0 << "\n";

    std::exit(0);*/

    for( int n = 0; n < NT; n++ ){
        
        float t { float(((float)n-0.5)*Dt) };

        add_Jz <<<Dg, Db>>> ( i_s, j_s, Ez_d, t ,Dt, t0, sig, EPS0 );
        update_Ez <<<Dg, Db>>> ( Nx, Ny, Ez_d, Hx_d, Hy_d, CEz1, CEz2 );

        /* Cuda 同期 */
        cudaDeviceSynchronize();

        update_Hx <<<Dg, Db>>> ( Nx, Ny, Hx_d, Ez_d, CHx );
        update_Hy <<<Dg, Db>>> ( Nx, Ny, Hy_d, Ez_d, CHy );

        cudaMemcpy( Ez, Ez_d, sizeof(float)*(Nx+1)*(Ny+1), cudaMemcpyDeviceToHost);

        std::string filename = "./result/ez_" + std::to_string(n) + ".dat";
        std::ofstream ofs(filename.c_str());

        for( int i = 0; i <= Nx; i++ ){
            for( int j = 0; j <= Ny; j++ ){
                ofs << i << " " << j << " " << Ez[idx_Ez(i, j)] << "\n";
            }
            ofs << "\n";
        }

        ofs.close();

        std::cout << n << " " << Ez[idx_Ez(25, 25)] << "\n";
        cudaDeviceSynchronize();

    }

    cudaFree( Ez_d );
    cudaFree( Hx_d );
    cudaFree( Hy_d );

}