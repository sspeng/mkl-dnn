/*******************************************************************************
* Copyright 2019 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#include "ocl/ocl_types.h"

#if DT_F16 && !IS_FWD
#error "FP16 is not supported for BWD"
#endif

#define OFFTYPE ulong

#define OFF6(i0,D0,i1,D1,i2,D2,i3,D3,i4,D4,i5,D5) \
    ((((((i0)*(D1)+(i1))*(D2)+(i2))*(D3)+(i3))*(D4)+(i4))*(D5)+(i5))
#define OFF5(i0,D0,i1,D1,i2,D2,i3,D3,i4,D4)  \
    (((((i0)*(D1)+(i1))*(D2)+(i2))*(D3)+(i3))*(D4)+(i4))
#define OFF4(i0,D0,i1,D1,i2,D2,i3,D3) \
    ((((i0)*(D1)+(i1))*(D2)+(i2))*(D3)+(i3))
#define OFF3(i0,D0,i1,D1,i2,D2) \
    (((i0)*(D1)+(i1))*(D2)+(i2))
#define OFF2(i0,D0,i1,D1) \
    ((i0)*(D1)+(i1))

#define OFF_WS_STATES_LAYER(i0,i1,i2,i3,i4) \
    OFF5((i0), N_DIR, (i1), N_ITER + 1, (i2), N_STATES, (i3), BATCH, (i4), WIC)

#define OFF_WS_STATES(i0,i1,i2,i3,i4,i5) \
    OFF6((i0), N_LAYER + 1, (i1), N_DIR, (i2), N_ITER + 1, (i3), N_STATES, \
               (i4), BATCH, (i5), WIC)

#define OFF_WS_DIFF_STATES(i0,i1,i2,i3,i4,i5) \
    OFF6((i0), N_LAYER + 1,(i1), N_DIR, (i2), N_ITER + 1, (i3), N_STATES + 1, \
               (i4), BATCH, (i5), WIC)

#define OFF_WS_GATES(i0,i1,i2,i3,i4,i5) \
    OFF6((i0), N_LAYER, (i1), N_DIR, (i2), N_ITER, (i3), BATCH, (i4), N_GATES, \
               (i5), DIC)

// for cell - shorter forms

#define CELL_WS_GATES(i3,i4,i5) OFF_WS_GATES(0,0,0,i3,i4,i5)
#define CELL_WS_STATES(i3,i4,i5) OFF_WS_STATES(0,0,0,i3,i4,i5)
#define CELL_WS_DIFF_STATES(i3,i4,i5) OFF_WS_DIFF_STATES(0,0,0,i3,i4,i5)

#define OFF_KER_STATES(i0,i1,i2) \
    OFF3((i0), N_STATES, (i1), BATCH, (i2), WIC)
#define OFF_KER_GATES(i0,i1,i2) \
    OFF3((i0), BATCH, (i1), N_GATES, (i2), DIC)
#define OFF_KER_BIAS(i0,i1) \
    OFF2((i0), N_GATES, (i1), DIC)

#define OFF_A0(i0,i1,i2) \
    OFF3((i0), SLC, (i1), N_GATES, (i2), DIC)
#define OFF_A1(i0,i1,i2) \
    OFF3((i0), SIC, (i1), N_GATES, (i2), DIC)

#define SRC_L_OFF(x0, x1, x2) ( \
    ((x0) % SRC_L_B0) * SRC_L_SB0 + ((x0) / SRC_L_B0) * SRC_L_S0 + \
    ((x1) % SRC_L_B1) * SRC_L_SB1 + ((x1) / SRC_L_B1) * SRC_L_S1 + \
    ((x2) % SRC_L_B2) * SRC_L_SB2 + ((x2) / SRC_L_B2) * SRC_L_S2)
#define SRC_I_OFF(x0, x1, x2, x3, x4) ( \
    ((x0) % SRC_I_B0) * SRC_I_SB0 + ((x0) / SRC_I_B0) * SRC_I_S0 + \
    ((x1) % SRC_I_B1) * SRC_I_SB1 + ((x1) / SRC_I_B1) * SRC_I_S1 + \
    ((x2) % SRC_I_B2) * SRC_I_SB2 + ((x2) / SRC_I_B2) * SRC_I_S2 + \
    ((x3) % SRC_I_B3) * SRC_I_SB3 + ((x3) / SRC_I_B3) * SRC_I_S3 + \
    ((x4) % SRC_I_B4) * SRC_I_SB4 + ((x4) / SRC_I_B4) * SRC_I_S4)
#define DST_L_OFF(x0, x1, x2) ( \
    ((x0) % DST_L_B0) * DST_L_SB0 + ((x0) / DST_L_B0) * DST_L_S0 + \
    ((x1) % DST_L_B1) * DST_L_SB1 + ((x1) / DST_L_B1) * DST_L_S1 + \
    ((x2) % DST_L_B2) * DST_L_SB2 + ((x2) / DST_L_B2) * DST_L_S2)
#define DST_I_OFF(x0, x1, x2, x3, x4) ( \
    ((x0) % DST_I_B0) * DST_I_SB0 + ((x0) / DST_I_B0) * DST_I_S0 + \
    ((x1) % DST_I_B1) * DST_I_SB1 + ((x1) / DST_I_B1) * DST_I_S1 + \
    ((x2) % DST_I_B2) * DST_I_SB2 + ((x2) / DST_I_B2) * DST_I_S2 + \
    ((x3) % DST_I_B3) * DST_I_SB3 + ((x3) / DST_I_B3) * DST_I_S3 + \
    ((x4) % DST_I_B4) * DST_I_SB4 + ((x4) / DST_I_B4) * DST_I_S4)
#define BIAS_OFF(x0, x1, x2, x3) ( \
    ((x0) % BIAS_B0) * BIAS_SB0 + ((x0) / BIAS_B0) * BIAS_S0 + \
    ((x1) % BIAS_B1) * BIAS_SB1 + ((x1) / BIAS_B1) * BIAS_S1 + \
    ((x2) % BIAS_B2) * BIAS_SB2 + ((x2) / BIAS_B2) * BIAS_S2 + \
    ((x3) % BIAS_B3) * BIAS_SB3 + ((x3) / BIAS_B3) * BIAS_S3)

#define DIFF_SRC_L_OFF(x0, x1, x2) ( \
    ((x0) % DIFF_SRC_L_B0) * DIFF_SRC_L_SB0 \
    + ((x0) / DIFF_SRC_L_B0) * DIFF_SRC_L_S0 + \
    ((x1) % DIFF_SRC_L_B1) * DIFF_SRC_L_SB1 \
    + ((x1) / DIFF_SRC_L_B1) * DIFF_SRC_L_S1 + \
    ((x2) % DIFF_SRC_L_B2) * DIFF_SRC_L_SB2 \
    + ((x2) / DIFF_SRC_L_B2) * DIFF_SRC_L_S2)
#define DIFF_SRC_I_OFF(x0, x1, x2, x3, x4) ( \
    ((x0) % DIFF_SRC_I_B0) * DIFF_SRC_I_SB0 \
    + ((x0) / DIFF_SRC_I_B0) * DIFF_SRC_I_S0 + \
    ((x1) % DIFF_SRC_I_B1) * DIFF_SRC_I_SB1 \
    + ((x1) / DIFF_SRC_I_B1) * DIFF_SRC_I_S1 + \
    ((x2) % DIFF_SRC_I_B2) * DIFF_SRC_I_SB2 \
    + ((x2) / DIFF_SRC_I_B2) * DIFF_SRC_I_S2 + \
    ((x3) % DIFF_SRC_I_B3) * DIFF_SRC_I_SB3 \
    + ((x3) / DIFF_SRC_I_B3) * DIFF_SRC_I_S3 + \
    ((x4) % DIFF_SRC_I_B4) * DIFF_SRC_I_SB4 \
    + ((x4) / DIFF_SRC_I_B4) * DIFF_SRC_I_S4)
#define DIFF_BIAS_OFF(x0, x1, x2, x3) ( \
    ((x0) % DIFF_BIAS_B0) * DIFF_BIAS_SB0 \
    + ((x0) / DIFF_BIAS_B0) * DIFF_BIAS_S0 + \
    ((x1) % DIFF_BIAS_B1) * DIFF_BIAS_SB1 \
    + ((x1) / DIFF_BIAS_B1) * DIFF_BIAS_S1 + \
    ((x2) % DIFF_BIAS_B2) * DIFF_BIAS_SB2 \
    + ((x2) / DIFF_BIAS_B2) * DIFF_BIAS_S2 + \
    ((x3) % DIFF_BIAS_B3) * DIFF_BIAS_SB3 \
    + ((x3) / DIFF_BIAS_B3) * DIFF_BIAS_S3)

DATA_T one_m_square(DATA_T a) {
    return 1.0f - a * a;
}
DATA_T relu_fwd(DATA_T s, DATA_T alpha) {
    return s > 0 ? s : s * alpha;
}
DATA_T tanh_fwd(DATA_T s) {
    return tanh(s);
}
DATA_T logistic_fwd(DATA_T s) {
    return 1 / (1 + exp((float) -s));
}
DATA_T logistic_bwd(DATA_T dd, DATA_T s) {
    DATA_T v = logistic_fwd(s);
    return dd * v * (1 - v);
}
DATA_T relu_bwd(DATA_T dd, DATA_T s, DATA_T alpha) {
    return s > 0 ? dd : dd * alpha;
}
DATA_T tanh_bwd(DATA_T dd, DATA_T s) {
    const float th = tanh((float)s);
    return dd * (1 - th) * (1 + th);
}
DATA_T activation_fwd(DATA_T s, DATA_T alpha, DATA_T cliping) {
#if ACTIVATION_KIND == ELTWISE_RELU
        return relu_fwd(s, alpha);
#elif ACTIVATION_KIND == ELTWISE_TANH
        return tanh_fwd(s);
#elif ACTIVATION_KIND == ELTWISE_LOGISTIC
        return logistic_fwd(s);
#else
#error "Unsupported activation_kind"
#endif
}

DATA_T activation_bwd(DATA_T dd, DATA_T s, DATA_T alpha, DATA_T cliping) {
#if ACTIVATION_KIND == ELTWISE_RELU
        return relu_bwd(dd, s, alpha);
#elif ACTIVATION_KIND == ELTWISE_TANH
        return tanh_bwd(dd, s);
#elif ACTIVATION_KIND == ELTWISE_LOGISTIC
        return logistic_bwd(dd, s);
#else
#error "Unsupported activation_kind"
#endif
}

__kernel void ref_rnn_copy_init_layer_kernel(__global DATA_T *ws,
        __global DATA_T *src_base, int lr, int rl) {

#if IS_FWD
    const int it = get_global_id(2);
    const int b = get_global_id(1);
    const int c = get_global_id(0);
    __global DATA_T *dst;
    __global DATA_T *dst_base = ws + WS_STATES_OFFSET;
    __global DATA_T *src = src_base + SRC_L_OFF(it, 0, 0 ) + b * SLC + c;

    if (lr) {
        dst = dst_base + OFF_WS_STATES_LAYER(0, it+1, 0, b, c);
        dst[0] = src[0];
    }
    if (rl) {
        dst = dst_base + OFF_WS_STATES_LAYER(N_DIR-1, N_ITER-it, 0, b, c);
        dst[0] = src[0];
    }
#else
    const int it = get_global_id(1);
    const int b = get_global_id(0);

    __global DATA_T *dst = ws + WS_DIFF_STATES_OFFSET;
    __global DATA_T *src = src_base + DIFF_SRC_L_OFF(it, b, 0 );

#if DIRECTION_KIND == CONCAT
    for (int s = 0; s < DIC; s++) {
        dst[OFF_WS_DIFF_STATES(N_LAYER,0,it,N_STATES,b,s)] = src[s];
        dst[OFF_WS_DIFF_STATES(N_LAYER,1,it,N_STATES,b,s)] = src[DIC + s];
    }
#elif DIRECTION_KIND == SUM
    for (int s = 0; s < DIC; s++) {
        dst[OFF_WS_DIFF_STATES(N_LAYER,0,it,N_STATES,b,s)] = src[s];
        dst[OFF_WS_DIFF_STATES(N_LAYER,1,it,N_STATES,b,s)] = src[s];
    }
#else
    for (int s = 0; s < DIC; s++) {
        dst[OFF_WS_DIFF_STATES(N_LAYER,0,it,N_STATES,b,s)] = src[s];
    }
#endif
#endif
}

__kernel void ref_rnn_copy_init_iter_kernel(__global DATA_T *ws,
        __global DATA_T *src_base) {
    const int s = get_global_id(0);
    const int lay = get_global_id(2) / N_DIR;
    const int dir = get_global_id(2) % N_DIR;
    const int state = get_global_id(1) / BATCH;
    const int b = get_global_id(1) % BATCH;

#if IS_FWD
    __global DATA_T *dst = ws + WS_STATES_OFFSET;
    dst[OFF_WS_STATES(lay + 1, dir, 0, state, b, s)] = src_base
        ? src_base[SRC_I_OFF(lay, dir, state, b, s)]
        : 0.0;
#else
    __global DATA_T *dst = ws + WS_DIFF_STATES_OFFSET;
    dst[OFF_WS_DIFF_STATES(lay, dir, N_ITER, state, b, s)] = src_base
        ? src_base[DIFF_SRC_I_OFF(lay, dir, state, b, s)]
        : 0.0;
#endif
}

__kernel void ref_rnn_copy_res_layer_kernel(__global DATA_T *ws,
        __global DATA_T *dst_base, int lr, int rl) {

    const int it = get_global_id(2);
    const int b = get_global_id(1);
    const int s = get_global_id(0);

#if IS_FWD
    __global DATA_T *src_base = ws + WS_STATES_OFFSET;
    int dir = 0;
    if (lr) {
        dst_base[DST_L_OFF(it, b, dir * DIC + s)] =
                src_base[OFF_WS_STATES(N_LAYER, dir, it+1, 0, b, s)];
        dir = 1;
    }
    if (rl) {
#if DIRECTION_KIND == SUM
            dst_base[DST_L_OFF(it, b, s)] +=
                src_base[OFF_WS_STATES(N_LAYER, dir, N_ITER - it, 0, b, s)];
#else
            dst_base[DST_L_OFF(it, b, dir * DIC + s)] =
                src_base[OFF_WS_STATES(N_LAYER, dir, N_ITER - it, 0, b, s)];
#endif
    }
#else // BWD
    __global DATA_T *src_base = ws + WS_DIFF_STATES_OFFSET;
    int dir = 0;

#if DIRECTION_KIND == R2L
    const int iter = N_ITER - 1 - it;
#else
    const int iter = it;
#endif
    DATA_T res = src_base[OFF_WS_DIFF_STATES(0, 0, it, N_STATES, b, s)];
#if N_DIR > 1
    res += src_base[OFF_WS_DIFF_STATES(0, 1, N_ITER - 1 - it, N_STATES, b, s)];
#endif
    dst_base[DST_L_OFF(iter, b, dir * SLC + s)] = res;
#endif

}

__kernel void ref_rnn_copy_res_iter_kernel(__global DATA_T *ws,
        __global DATA_T *dst_base) {
    const int s = get_global_id(0);
    const int lay = get_global_id(2) / N_DIR;
    const int dir = get_global_id(2) % N_DIR;
    const int state = get_global_id(1) / BATCH;
    const int b = get_global_id(1) % BATCH;

#if IS_FWD
    __global DATA_T *src_base = ws + WS_STATES_OFFSET;
    if (dst_base) {
        dst_base[DST_I_OFF(lay, dir, state, b, s)] =
            src_base[OFF_WS_STATES(lay + 1, dir, N_ITER, state, b, s)];
    }
#else
    __global DATA_T *src_base = ws + WS_DIFF_STATES_OFFSET;
    if (dst_base) {
       dst_base[DST_I_OFF(lay, dir, state, b, s)] =
                src_base[OFF_WS_DIFF_STATES(lay, dir, 0, state, b, s)];
    }
#endif
}

__kernel void ref_rnn_ws_set_kernel(__global DATA_T *ws, OFFTYPE ws_offset,
        float val) {
    __global DATA_T *dst = ws + ws_offset;
    dst[get_global_id(0)] = CONVERT_DATA_T(val);
}

__kernel void ref_rnn_elemwise_fwd_kernel(int dir, int lay, int iter,
        __global DATA_T *ws, __global DATA_T *bias_base) {

    const int i = get_global_id(0); // batch
    const int j = get_global_id(1); // dic

    const __global DATA_T *states_tm1_l = ws + WS_STATES_OFFSET
            + OFF_WS_STATES(lay + 1, dir, iter, 0, 0, 0);
    const __global DATA_T *bias = bias_base + BIAS_OFF(lay, dir, 0, 0);
    __global DATA_T *ws_gates = ws + WS_GATES_OFFSET
            + OFF_WS_GATES(lay, dir, iter, 0, 0, 0);
    __global DATA_T *states_t_l = ws + WS_STATES_OFFSET
            + OFF_WS_STATES(lay + 1, dir, iter + 1, 0, 0, 0);

#if CELL_KIND == VANILLA_LSTM

    DATA_T g_i = logistic_fwd(
            ws_gates[CELL_WS_GATES(i, 0, j)] + bias[OFF_KER_BIAS(0, j)]);
    DATA_T g_f = logistic_fwd(
            ws_gates[CELL_WS_GATES(i, 1, j)] + bias[OFF_KER_BIAS(1, j)]);
    DATA_T g_z = tanh_fwd(
            ws_gates[CELL_WS_GATES(i, 2, j)] + bias[OFF_KER_BIAS(2, j)]);
    DATA_T g_o = logistic_fwd(
            ws_gates[CELL_WS_GATES(i, 3, j)] + bias[OFF_KER_BIAS(3, j)]);

    ws_gates[CELL_WS_GATES(i, 0, j)] = g_f;
    ws_gates[CELL_WS_GATES(i, 1, j)] = g_i;
    ws_gates[CELL_WS_GATES(i, 2, j)] = g_z;
    ws_gates[CELL_WS_GATES(i, 3, j)] = g_o;

    DATA_T Ct = g_f * states_tm1_l[CELL_WS_STATES(1, i, j)] + g_i * g_z;
    DATA_T Ht = g_o * tanh_fwd(Ct);

    states_t_l[CELL_WS_STATES(0, i, j)] = Ht;
    states_t_l[CELL_WS_STATES(1, i, j)] = Ct;

#elif CELL_KIND == VANILLA_RNN
    DATA_T g = activation_fwd(
            ws_gates[CELL_WS_GATES(i, 0, j)] + bias[OFF_KER_BIAS(0, j)], 0, 0);

    ws_gates[CELL_WS_GATES(i, 0, j)] = g;

    states_t_l[CELL_WS_STATES(0, i, j)] = g;

#else
#error "Wrong cell kind"
#endif
}

__kernel void ref_rnn_elemwise_bwd_kernel(int dir, int lay, int iter,
        __global DATA_T *ws, __global DATA_T *bias_base) {
    const int i = get_global_id(0); // batch
    const int j = get_global_id(1); // dic

#if CELL_KIND == VANILLA_LSTM
    __global DATA_T *ws_gates = ws + WS_GATES_OFFSET
        + OFF_WS_GATES(lay, dir, iter, 0, 0, 0);
    __global DATA_T *states_t_l = ws + WS_STATES_OFFSET
        + OFF_WS_STATES(lay + 1, dir, iter + 1, 0, 0, 0);
    __global DATA_T *states_tm1_l = ws + WS_STATES_OFFSET
        + OFF_WS_STATES(lay + 1, dir, iter, 0, 0, 0);
    __global DATA_T *diff_states_t_l = ws + WS_DIFF_STATES_OFFSET
        + OFF_WS_DIFF_STATES(lay, dir, iter, 0, 0, 0);
    __global DATA_T *diff_states_tp1_l = ws + WS_DIFF_STATES_OFFSET
        + OFF_WS_DIFF_STATES(lay, dir, iter + 1, 0, 0, 0);
    __global DATA_T *diff_states_t_lp1 = ws + WS_DIFF_STATES_OFFSET
        + OFF_WS_DIFF_STATES(lay + 1, dir, iter, 0, 0, 0);

    DATA_T Ct = states_t_l[CELL_WS_STATES(1, i, j)];
    /// @todo save it in the workspace in fwd pass or recompute it to
    /// save bw
    DATA_T tanhCt = tanh_fwd(Ct);
    // we have 2 incoming diffs on Ht
    DATA_T dHt = diff_states_tp1_l[CELL_WS_DIFF_STATES(0, i, j)]
            + diff_states_t_lp1[CELL_WS_DIFF_STATES(N_STATES, i, j)];
    DATA_T dCt = diff_states_tp1_l[CELL_WS_DIFF_STATES(1, i, j)]
            + one_m_square(tanhCt) * ws_gates[CELL_WS_GATES(i, 2, j)] * dHt;

    DATA_T dG0 = states_tm1_l[CELL_WS_STATES(1, i, j)]
            * logistic_bwd(dCt, ws_gates[CELL_WS_GATES(i, 0, j)]);
    DATA_T dG1 = ws_gates[CELL_WS_GATES(i, 3, j)]
            * logistic_bwd(dCt, ws_gates[CELL_WS_GATES(i, 1, j)]);
    DATA_T dG2 = logistic_bwd(tanhCt * dHt, ws_gates[CELL_WS_GATES(i, 2, j)]);
    DATA_T dG3 = ws_gates[CELL_WS_GATES(i, 1, j)]
            * tanh_bwd(dCt, ws_gates[CELL_WS_GATES(i, 3, j)]);

    diff_states_t_l[CELL_WS_DIFF_STATES(1, i, j)]
        = dCt * ws_gates[CELL_WS_GATES(i, 0, j)];

    ws_gates[CELL_WS_GATES(i, 0, j)] = dG0;
    ws_gates[CELL_WS_GATES(i, 1, j)] = dG1;
    ws_gates[CELL_WS_GATES(i, 2, j)] = dG2;
    ws_gates[CELL_WS_GATES(i, 3, j)] = dG3;

#elif CELL_KIND == VANILLA_RNN
    __global DATA_T *ws_gates = ws + WS_GATES_OFFSET
        + OFF_WS_GATES(lay, dir, iter, i, 0, j);
    __global DATA_T *ws_diff_states = ws + WS_DIFF_STATES_OFFSET;
    __global DATA_T *diff_states_t_lp1 = ws_diff_states
        + OFF_WS_DIFF_STATES(lay + 1, dir, iter, N_STATES, i, j);
    __global DATA_T *diff_states_tp1_l = ws_diff_states
        + OFF_WS_DIFF_STATES(lay, dir, iter + 1, 0, i, j);

    const DATA_T dH = diff_states_t_lp1[0] + diff_states_tp1_l[0];

    DATA_T g = ws_gates[0];
    ws_gates[0] = activation_bwd(dH, g, 0., 0.);
#else
#error "Wrong cell kind"
#endif
}

__kernel void ref_rnn_gemm_kernel(int is_A_trans, int is_B_trans, int k,
        __global DATA_T *a_base, OFFTYPE a_offset, int strideA_m, int strideA_k,
        __global DATA_T *b_base, OFFTYPE b_offset, int strideB_n, int strideB_k,
        __global DATA_T *c_base, OFFTYPE c_offset, int strideC_m, int strideC_n,
        const float beta_) {

    const int i = get_global_id(0); // m
    const int j = get_global_id(1); // n

    const DATA_T beta = CONVERT_DATA_T(beta_);

    const int lda = strideA_m;
    const int ldb = is_B_trans ? strideB_n : strideB_k;
    const int ldc = strideC_m;

    __global DATA_T *a = a_base + a_offset;
    __global DATA_T *b = b_base + b_offset;
    __global DATA_T *c = c_base + c_offset;

    DATA_T t = 0.0f;
    for (int l = 0; l < k; l++) {
        t += a[i + l*lda] * (is_B_trans ? b[j + l*ldb] : b[l + j*ldb]);
    }

    if (beta == 0.0) {
        c[i + j*ldc] = t;
    } else {
        c[i + j*ldc] = beta * c[i + j*ldc] + t;
    }
}

__kernel void ref_rnn_gates_reduction_kernel(int dir, int lay, int iter,
        __global DATA_T *diff_bias_base, __global DATA_T *ws) {
#if !IS_FWD
    const int i = get_global_id(0); // n_gates
    const int k = get_global_id(1); // dic

    __global DATA_T *diff_bias = diff_bias_base + DIFF_BIAS_OFF(lay, dir, 0, 0);
    __global DATA_T *ws_gates = ws + WS_GATES_OFFSET
        + OFF_WS_GATES(lay, dir, iter, 0, 0, 0);

    for (int j = 0; j < BATCH; j++) {
        diff_bias[i * DIC + k] += ws_gates[(j * N_GATES + i) * DIC + k];
    }
#endif
}
