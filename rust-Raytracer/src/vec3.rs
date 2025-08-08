use std::ops::{Add, AddAssign, Div, DivAssign, Index, Mul, MulAssign, Neg, Sub};

#[derive(Copy, Clone, Debug, Default)]
pub struct Vec3(pub [f64; 3]);

pub type Point3 = Vec3;

impl Vec3 {
    pub fn new(x: f64, y: f64, z: f64) -> Self {
        Self([x, y, z])
    }
    pub fn x(&self) -> f64 {
        self.0[0]
    }
    pub fn y(&self) -> f64 {
        self.0[1]
    }
    pub fn z(&self) -> f64 {
        self.0[2]
    }
    pub fn length_squared(&self) -> f64 {
        self.0[0] * self.0[0] + self.0[1] * self.0[1] + self.0[2] * self.0[2]
    }
    pub fn length(&self) -> f64 {
        self.length_squared().sqrt()
    }
    pub fn near_zero(&self) -> bool {
        let s = 1e-8;
        self.0.iter().all(|v| v.abs() < s)
    }
    pub fn dot(u: Vec3, v: Vec3) -> f64 {
        u.0[0] * v.0[0] + u.0[1] * v.0[1] + u.0[2] * v.0[2]
    }
    pub fn cross(u: Vec3, v: Vec3) -> Vec3 {
        Vec3::new(
            u.0[1] * v.0[2] - u.0[2] * v.0[1],
            u.0[2] * v.0[0] - u.0[0] * v.0[2],
            u.0[0] * v.0[1] - u.0[1] * v.0[0],
        )
    }
    pub fn unit(v: Vec3) -> Vec3 {
        v / v.length()
    }
}

impl Index<usize> for Vec3 {
    type Output = f64;
    fn index(&self, idx: usize) -> &Self::Output {
        &self.0[idx]
    }
}

impl Add for Vec3 {
    type Output = Vec3;
    fn add(self, rhs: Vec3) -> Vec3 {
        Vec3::new(
            self.0[0] + rhs.0[0],
            self.0[1] + rhs.0[1],
            self.0[2] + rhs.0[2],
        )
    }
}
impl Sub for Vec3 {
    type Output = Vec3;
    fn sub(self, rhs: Vec3) -> Vec3 {
        Vec3::new(
            self.0[0] - rhs.0[0],
            self.0[1] - rhs.0[1],
            self.0[2] - rhs.0[2],
        )
    }
}
impl Mul for Vec3 {
    type Output = Vec3;
    fn mul(self, rhs: Vec3) -> Vec3 {
        Vec3::new(
            self.0[0] * rhs.0[0],
            self.0[1] * rhs.0[1],
            self.0[2] * rhs.0[2],
        )
    }
}
impl Mul<f64> for Vec3 {
    type Output = Vec3;
    fn mul(self, t: f64) -> Vec3 {
        Vec3::new(self.0[0] * t, self.0[1] * t, self.0[2] * t)
    }
}
impl Div<f64> for Vec3 {
    type Output = Vec3;
    fn div(self, t: f64) -> Vec3 {
        self * (1.0 / t)
    }
}
impl Neg for Vec3 {
    type Output = Vec3;
    fn neg(self) -> Vec3 {
        Vec3::new(-self.0[0], -self.0[1], -self.0[2])
    }
}
impl AddAssign for Vec3 {
    fn add_assign(&mut self, rhs: Vec3) {
        self.0[0] += rhs.0[0];
        self.0[1] += rhs.0[1];
        self.0[2] += rhs.0[2];
    }
}
impl MulAssign<f64> for Vec3 {
    fn mul_assign(&mut self, t: f64) {
        self.0[0] *= t;
        self.0[1] *= t;
        self.0[2] *= t;
    }
}
impl DivAssign<f64> for Vec3 {
    fn div_assign(&mut self, t: f64) {
        *self *= 1.0 / t;
    }
}
