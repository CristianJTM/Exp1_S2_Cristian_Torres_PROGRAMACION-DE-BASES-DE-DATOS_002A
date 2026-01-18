--Se limpia la tabla
TRUNCATE TABLE USUARIO_CLAVE;

SET SERVEROUTPUT ON;

--Para la fecha de proceso se usa variable Bind, ya que no se puede con DATE se uso varchar y se trasforma luego en DATE en el bloque
VARIABLE b_fecha_proceso VARCHAR2(10);
EXEC :b_fecha_proceso := TO_CHAR(SYSDATE, 'DD-MM-YYYY');
/

DECLARE
     --inicia en 100 y se incrementa de 10 en 10
    v_empleado_id usuario_clave.id_emp%TYPE := 100;
    v_numrun_empleado usuario_clave.numrun_emp%TYPE;
    v_dvrun_empleado usuario_clave.dvrun_emp%TYPE;
    v_nombre_empleado usuario_clave.nombre_empleado%TYPE;
    v_nombre_usuario usuario_clave.nombre_usuario%TYPE;
    v_clave_usuario usuario_clave.clave_usuario%TYPE;
    
    --cantidad de empleados a procesar
    v_total_empleados NUMBER;
    
    --variables adicionales para construir el usuario
    v_estado_civil estado_civil.nombre_estado_civil%TYPE;
    v_primer_nombre empleado.pnombre_emp%TYPE;
    v_sueldo_base empleado.sueldo_base%TYPE;
    v_fecha_contratacion empleado.fecha_contrato%TYPE;
    v_anios_servicio NUMBER;
    
    --variables adicionales para construir la contraseña
    v_fecha_nacimiento empleado.fecha_nac%TYPE;
    v_appaterno_empleado empleado.appaterno_emp%TYPE;
    
BEGIN
    --Se obtiene la cantidad de empleados para el FOR
    SELECT COUNT(*)
    INTO v_total_empleados
    FROM empleado;
    
    --recorre cada empleado
    FOR i IN 1 .. v_total_empleados LOOP
    
         --Obtención de los datos necesarios del empleado
        SELECT e.numrun_emp,
            e.dvrun_emp,
            e.pnombre_emp || ' ' || e.snombre_emp || ' ' || e.appaterno_emp || ' ' || e.apmaterno_emp,
            ec.nombre_estado_civil,
            e.pnombre_emp,
            e.sueldo_base,
            e.fecha_contrato,
            e.fecha_nac,
            e.appaterno_emp
        INTO v_numrun_empleado,
            v_dvrun_empleado,
            v_nombre_empleado,
            v_estado_civil,
            v_primer_nombre,
            v_sueldo_base,
            v_fecha_contratacion,
            v_fecha_nacimiento,
            v_appaterno_empleado
        FROM EMPLEADO e
        JOIN ESTADO_CIVIL ec
            ON ec.id_estado_civil = e.id_estado_civil
        WHERE id_emp = v_empleado_id;
        
        --Años de servicio
        v_anios_servicio := TRUNC(MONTHS_BETWEEN( TO_DATE(:b_fecha_proceso, 'DD-MM-YYYY'), v_fecha_contratacion) / 12);
        
        --Nombre de usuario
        
        v_nombre_usuario := LOWER(SUBSTR(v_estado_civil, 1,1)) || 
                            SUBSTR(v_primer_nombre, 1 ,3) || 
                            LENGTH(v_primer_nombre) ||
                            '*' ||
                            SUBSTR(v_sueldo_base,-1) ||
                            v_dvrun_empleado || 
                            v_anios_servicio;
        
        --Agrega x si tiene mas de 10 años de servicio se le agrega al nombre de usuario    
        IF v_anios_servicio < 10 THEN
           v_nombre_usuario := v_nombre_usuario || 'x';
        END IF;
        
        --Clave de usuario
        
        v_clave_usuario :=  SUBSTR(TO_CHAR(v_numrun_empleado), 3, 1) || 
                            (EXTRACT(YEAR FROM v_fecha_nacimiento) + 2) || 
                            (SUBSTR(v_sueldo_base - 1,-3));
        
        --Se agregan los caracteres del apellido paterno segun estado civil
        IF TRIM(UPPER(v_estado_civil)) IN ('CASADO', 'ACUERDO DE UNION CIVIL') THEN
            v_clave_usuario := v_clave_usuario || LOWER(SUBSTR(v_appaterno_empleado, 1 ,2));
        ELSIF TRIM(UPPER(v_estado_civil)) IN ('DIVORCIADO', 'SOLTERO') THEN
            v_clave_usuario := v_clave_usuario || LOWER(SUBSTR(v_appaterno_empleado, 1 ,1) || SUBSTR(v_appaterno_empleado, -1));
        ELSIF TRIM(UPPER(v_estado_civil)) = 'VIUDO' THEN
            v_clave_usuario := v_clave_usuario || LOWER(SUBSTR(v_appaterno_empleado, -3 ,1) || SUBSTR(v_appaterno_empleado, -2 ,1));
        ELSE
            v_clave_usuario := v_clave_usuario || LOWER(SUBSTR(v_appaterno_empleado, -2 ,2));
        END IF;
        
        --Se termina de crear la clave de usuario
        v_clave_usuario :=  v_clave_usuario || 
                            v_empleado_id ||
                            EXTRACT(MONTH FROM  TO_DATE(:b_fecha_proceso, 'DD-MM-YYYY')) ||
                            EXTRACT(YEAR FROM  TO_DATE(:b_fecha_proceso, 'DD-MM-YYYY'));
                            
         
        --Se insertan los datos en la tabla usuario_clave
        INSERT INTO usuario_clave
        VALUES (
            v_empleado_id,
            v_numrun_empleado,
            v_dvrun_empleado,
            v_nombre_empleado,
            v_nombre_usuario,
            v_clave_usuario
        );
        
        --Se incrementa el id para evaluar el siguiente empleado
        v_empleado_id := v_empleado_id + 10;
        
        DBMS_OUTPUT.PUT_LINE('Cliente procesado: ' || v_nombre_empleado);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al procesar cliente');
END;
/

--Consulta para confirmar tabla
SELECT * FROM USUARIO_CLAVE;