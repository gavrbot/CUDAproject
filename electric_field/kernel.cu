#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <GL2/glew.h>
#include <GL2/freeglut.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <iostream>
#include <math.h>
#include <conio.h>
#include <time.h>

#define PI 3.14

struct Particle
{
	float x,y,vx,vy,m,r1 = rand()%255, r2 = rand() % 255, r3 = rand() % 255;
	Particle()
	{
		this->x = 0;
		this->y = 0;
		this->vx = 0;
		this->vy = 0;
		this->m = 0;
	}
	Particle(float x, float y, float vx, float vy, float m)
	{
		this->x = x;
		this->y = y;
		this->vx = vx;
		this->vy = vy;
		this->m = m;
	}
};

int N;

Particle *particles;

Particle* dev_part;

float floatRand() {

	return float(rand()) / (float(RAND_MAX) + 1.0);
}

__global__ void calculating(Particle* dev_part, int N)
{
	int i = threadIdx.x + blockIdx.x * blockDim.x;
	Particle &p0 = dev_part[i];
	for (int j = 0; j < N; ++j) {
		if (j == i)continue;
		const Particle &p = dev_part[j];
		float d = sqrt(pow((p0.x - p.x), 2) + pow((p0.y - p.y), 2));
		if (d > 3)
		{
			p0.vx += 0.00067 * p.m / pow(d, 2) * (p.x - p0.x) / d;
			p0.vy += 0.00067 * p.m / pow(d, 2) * (p.y - p0.y) / d;
		}
	}
	p0.x += p0.vx;
	p0.y += p0.vy;
}

void drawFilledCircle(GLfloat x, GLfloat y, GLfloat radius) {
	int triangleAmount = 20;
	GLfloat twicePi = 2.0f * PI;
	glBegin(GL_TRIANGLE_FAN);
	glVertex2f(x, y);
	for (int i = 0; i <= triangleAmount; i++) {
		glVertex2f(
			x + (radius * cos(i *  twicePi / triangleAmount)),
			y + (radius * sin(i * twicePi / triangleAmount))
		);
	}
	glEnd();
}


void display()
{
	glClear(GL_COLOR_BUFFER_BIT);
	//glBegin(GL_POINTS);
	for (int i = 0; i < N; ++i) {
		glColor3b(particles[i].r1, particles[i].r2, particles[i].r3);
		//glVertex2f(particles[i].x, particles[i].y);
		drawFilledCircle(particles[i].x, particles[i].y, 0.5);//particles[i].m
	}
	//glEnd();
	glutSwapBuffers();
}

void timer(int = 0)
{
	cudaMemcpy(dev_part,particles,N*sizeof(Particle),cudaMemcpyHostToDevice);
	calculating<<<1, N>>>(dev_part,N);
	cudaThreadSynchronize();
	cudaMemcpy(particles, dev_part, N * sizeof(Particle), cudaMemcpyDeviceToHost);
	display();
	glutTimerFunc(1, timer, 0);
}

int main(int argc, char **argv)
{
	bool circle = true;
	srand(time(0));
	while (circle) {
		system("cls");
		std::cout << "Welcome to the gravity modeling program! Choose your option to work with:\n1.Create objects with random parameters\n2.Create objects with custom parameteres\n3.Run default system \n0.Exit program\n";
		int key = _getch();
		switch (key)
		{
		case 48:
			circle = false;
			break;
		case 49:
			system("cls");
			std::cout << "Enter number of objects, but it should be in the interval [0,1024]:";
			do {
				std::cin >> N;
				if (N < 0|| N > 1024)std::cout << "Input is not correct. Please try again:";
			} while (N<0||N>1024);
			particles = (Particle*)malloc(N * sizeof(Particle));
			for (size_t i = 0; i < N; ++i)
			{
				particles[i] = Particle(rand() % 100 + 50, rand() % 100 + 50, floatRand() - 0.5, floatRand() - 0.5, rand() % 10);
			}
			std::cout << "Add heavy object to the system?(1-yes,0-no):";
			int ans;
			std::cin >> ans;
			switch (ans)
			{
			case 1:
				particles[0] = Particle(100, 100, 0, 0, 10000);
			default:
				break;
			}

			break;
		case 50:
			system("cls");
			std::cout << "Enter number of objects, but it should be in the interval [0,1024]:";
			do {
				std::cin >> N;
				if (N < 0 || N > 1024)std::cout << "Input is not correct. Please try again:";
			} while (N < 0 || N>1024);
			particles = (Particle*)malloc(N * sizeof(Particle));

			for (size_t i = 0; i < N; i++)
			{
				std::cout << "Entering parametrs of " << i+1 <<" particle\n";
				double x, y, vx, vy, m;
				std::cout << "Enter x coordinate:";
				do {
					std::cin >> x;
					if (x < 0 || x > 1024)std::cout << "Input is not correct. Please try again:";
				} while (x < 0);
				std::cout << "Enter y coordinate:";
				do {
					std::cin >> y;
					if (y < 0 || y > 1024)std::cout << "Input is not correct. Please try again:";
				} while (y < 0);
				std::cout << "Enter speed on x coordinate:";
				do {
					std::cin >> vx;
					if (vx < 0)std::cout << "Input is not correct. Please try again:";
				} while (vx < 0);
				std::cout << "Enter speed on y coordinate:";
				do {
					std::cin >> vy;
					if (vy < 0)std::cout << "Input is not correct. Please try again:";
				} while (vy < 0);
				std::cout << "Enter mass:";
				do {
					std::cin >> m;
					if (m < 0)std::cout << "Input is not correct. Please try again:";
				} while (m < 0);
				particles[i] = Particle(x, y, vx, vy, m);
			}
			break;
		case 51:
			N = 6;
			particles = (Particle*)malloc(N * sizeof(Particle));
			particles[0] = Particle(100, 100, 0, 0, 1000);//The Sun
			particles[1] = Particle(85, 100, 0, -0.23, 6);//Mercury
			particles[2] = Particle(40, 100, 0, 0.1, 10);//Earth
			particles[3] = Particle(25, 100, 0, -0.08, 5);//Mars
			particles[4] = Particle(70, 100, 0, 0.15, 8);//Venera
			particles[5] = Particle(35, 100, 0, 0.11, 0.1);//Moon
			break;
		default:
			circle = false;
			break;
		}
		if (circle) {
			cudaMalloc((void**)&dev_part, N * sizeof(Particle));
			glutInit(&argc, argv);
			glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
			glutInitWindowSize(1000, 800);
			glutInitWindowPosition(400, 100);
			glutCreateWindow("Gravitation");
			glClearColor(0, 0, 0, 1.0);
			glMatrixMode(GL_PROJECTION);
			glLoadIdentity();
			glOrtho(0, 200, 200, 0, -1, 1);
			glutDisplayFunc(display);
			timer();
			glutMainLoop();
			free(particles);
			cudaFree(dev_part);
		}
	}
}