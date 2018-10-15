import math
cos_const = 1

iteration = 50

for n in range(0, iteration):
    cos_const = cos_const * math.cos( math.atan(2**(-n) ) )

print("cos const", cos_const)

ans_angle = 30

ans_radian = ans_angle * math.pi / 180
ans_cos_val = math.cos(ans_radian)
ans_sin_val = math.sin(ans_radian)


tan_angle_const = [math.atan(2**(-i) ) for i in range(0, iteration)]

## initial_value
result_x = cos_const
result_y = 0
result_z = ans_radian

if ans_radian > 0:
    Sn = 1
else:
    Sn = -1


for i in range(0, iteration):

    tmp_x = result_x - Sn * result_y * 2**(-i)
    tmp_y = result_y + Sn * result_x * 2**(-i)
    tmp_z = result_z - Sn * math.atan(2**(-i) )

    result_x = tmp_x
    result_y = tmp_y
    result_z = tmp_z

    print(i, result_x, result_y, result_z, Sn, math.atan(2**(-i)) )

    # Sn = np.sign(result_z)
    if result_z > 0:
        Sn = 1
    else:
        Sn = -1

print('correct cos val:', ans_cos_val, 'cal_cos_val: ', result_x)
print('correct sin val:', ans_sin_val, 'cal_sin_val: ', result_y)
