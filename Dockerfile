FROM --platform=linux/amd64 mathworks/matlab:r2025b

USER root
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \
    chmod +x mpm && \
    ./mpm install \
    --release=R2025b \
    --destination=/opt/matlab/R2025b \
    --products \
    Statistics_and_Machine_Learning_Toolbox \
    Optimization_Toolbox \
    Global_Optimization_Toolbox \
    Econometrics_Toolbox \
    Parallel_Computing_Toolbox \
    Signal_Processing_Toolbox \
    Symbolic_Math_Toolbox \
    Curve_Fitting_Toolbox \
    Financial_Toolbox && \
    rm mpm
USER matlab
