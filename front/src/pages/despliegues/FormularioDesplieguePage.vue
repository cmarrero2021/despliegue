<template>
  <q-page padding class="flex flex-center bg-grey-2">
    <div class="full-width" style="max-width: 800px">
      <q-card class="shadow-2 q-mb-md">
        <q-card-section class="bg-primary text-white text-center">
          <div class="text-h6">Despliegue de las Brigadas de Atención Integral</div>
          <div class="text-subtitle2">a los Abuelos y Abuelas de la Patria</div>
        </q-card-section>
      </q-card>

      <q-stepper
        v-model="step"
        ref="stepper"
        color="primary"
        animated
        flat
        bordered
      >
        <!-- PASO 1: Ubicación -->
        <q-step
          :name="1"
          title="Ubicación"
          icon="place"
          :done="step > 1"
          :error="paso1Error"
        >
          <div class="q-col-gutter-md row">
            <div class="col-12 col-sm-6">
              <q-select
                v-model="form.estado_id"
                :options="estados"
                option-value="id"
                option-label="nombre"
                emit-value
                map-options
                label="Estado *"
                outlined
                :disable="estados.length === 1"
                @update:model-value="onEstadoChange"
                :error="v$.form.estado_id.$error"
              />
            </div>
            <div class="col-12 col-sm-6">
              <q-select
                v-model="form.municipio_id"
                :options="municipiosFiltrados"
                option-value="id"
                option-label="nombre"
                emit-value
                map-options
                label="Municipio *"
                outlined
                :disable="!form.estado_id || (municipiosDisponibles.length === 1 && municipiosFiltrados.length === 1)"
                @update:model-value="onMunicipioChange"
                :error="v$.form.municipio_id.$error"
              />
            </div>
            <div class="col-12 col-sm-6">
              <q-select
                v-model="form.parroquia_id"
                :options="parroquiasFiltradas"
                option-value="id"
                option-label="nombre"
                emit-value
                map-options
                label="Parroquia *"
                outlined
                :disable="!form.municipio_id || (parroquiasDisponibles.length === 1 && parroquiasFiltradas.length === 1)"
                @update:model-value="onParroquiaChange"
                :error="v$.form.parroquia_id.$error"
              />
            </div>
            <div class="col-12 col-sm-6">
              <q-select
                v-model="form.comuna_id"
                :options="comunas"
                option-value="id"
                option-label="nombre"
                emit-value
                map-options
                label="Comuna *"
                outlined
                :disable="!form.parroquia_id"
                use-input
                @new-value="createComuna"
                @filter="filterComunas"
                hint="Seleccione o escriba una nueva y presione Enter"
                :error="v$.form.comuna_id.$error && !form.nombre_comuna_nueva"
              />
            </div>
          </div>
        </q-step>

        <!-- PASO 2: Datos del Despliegue -->
        <q-step
          :name="2"
          title="Datos Básicos"
          icon="event"
          :done="step > 2"
          :error="paso2Error"
        >
          <div class="q-col-gutter-md row">
            <div class="col-12">
              <q-input
                v-model="form.fecha"
                mask="##/##/####"
                label="Fecha del despliegue (DD/MM/YYYY) *"
                outlined
                :error="v$.form.fecha.$error"
              >
                <template v-slot:append>
                  <q-icon name="event" class="cursor-pointer">
                    <q-popup-proxy cover transition-show="scale" transition-hide="scale">
                      <q-date v-model="form.fecha" mask="DD/MM/YYYY">
                        <div class="row items-center justify-end">
                          <q-btn v-close-popup label="Cerrar" color="primary" flat />
                        </div>
                      </q-date>
                    </q-popup-proxy>
                  </q-icon>
                </template>
              </q-input>
            </div>
            <div class="col-12">
              <div class="text-subtitle2 q-mb-sm">¿Hubo despliegue en el municipio? *</div>
              <q-option-group
                v-model="form.hubo_despliegue"
                :options="[
                  { label: 'Sí', value: true },
                  { label: 'No', value: false }
                ]"
                color="primary"
                inline
              />
            </div>
            <div class="col-12" v-if="form.hubo_despliegue">
              <div class="text-subtitle2 q-mb-sm">Instituciones presentes en el despliegue</div>
              <div class="row">
                <div class="col-12 col-sm-6" v-for="inst in institucionesList" :key="inst.id">
                  <q-checkbox v-model="form.instituciones" :val="inst.id" :label="inst.nombre" />
                </div>
              </div>
            </div>
          </div>
        </q-step>

        <!-- PASO 3: Validación (Estadísticas) -->
        <q-step
          :name="3"
          title="Validación"
          icon="bar_chart"
          :done="step > 3"
          :error="paso3Error"
          v-if="form.hubo_despliegue"
        >
          <div class="q-col-gutter-md row">
            <div class="col-12">
              <q-input
                v-model.number="form.adultos_listado"
                type="number"
                label="¿Cuántas personas adultas mayores están en el listado Patria para el despliegue de hoy? *"
                outlined
                :error="v$.form.adultos_listado.$error"
              />
            </div>
            <div class="col-12">
              <q-input
                v-model.number="form.adultos_visitados"
                type="number"
                label="¿Cuántas personas adultas mayores fueron visitadas? *"
                outlined
                :error="v$.form.adultos_visitados.$error"
              />
            </div>
            <div class="col-12">
              <q-input
                v-model.number="form.vulnerables_detectados"
                type="number"
                label="¿Cuántas personas adultas mayores se identificaron (VALIDADOS) como vulnerables? *"
                outlined
                :error="v$.form.vulnerables_detectados.$error"
                :error-message="v$.form.vulnerables_detectados.$error ? 'Vulnerables no puede ser mayor que los visitados' : ''"
              />
            </div>
            <div class="col-12">
              <q-input
                v-model.number="form.vulnerables_nuevos"
                type="number"
                label="¿Cuántas personas adultas mayores vulnerables se registraron que no estaban en la data inicial de Patria? *"
                outlined
                :error="v$.form.vulnerables_nuevos.$error"
              />
            </div>
            <div class="col-12">
              <q-input
                v-model="form.observaciones"
                type="textarea"
                label="Observaciones"
                outlined
                @update:model-value="val => form.observaciones = val.toUpperCase()"
              />
            </div>
          </div>
        </q-step>

        <!-- PASO 4: Confirmación -->
        <q-step
          :name="4"
          title="Confirmación"
          icon="check_circle"
        >
          <div class="text-center">
            <q-icon name="info" size="4rem" color="primary" class="q-mb-md" />
            <div class="text-h6">Revise los datos antes de guardar</div>
            <p class="text-grey-7">Asegúrese de que toda la información registrada sea correcta.</p>
          </div>
        </q-step>

        <template v-slot:navigation>
          <q-stepper-navigation class="flex justify-between">
            <q-btn v-if="step > 1" flat color="primary" @click="$refs.stepper.previous()" label="Atrás" class="q-ml-sm" />
            <q-space v-else />
            <q-btn v-if="step < 4" @click="siguientePaso" color="primary" label="Siguiente" />
            <q-btn v-else @click="submitForm" color="positive" label="Guardar" :loading="saving" />
          </q-stepper-navigation>
        </template>
      </q-stepper>
    </div>
  </q-page>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, numeric, minValue } from '@vuelidate/validators';
import { api } from 'boot/axios'; // Asumiendo que axios está configurado. Si no, usaremos fetch o instanciar axios
import { LocalStorage, Notify } from 'quasar';
import { useRouter } from 'vue-router';
import axios from 'axios';

const router = useRouter();
const step = ref(1);
const saving = ref(false);

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4131/api';

const today = new Date();
const currentFecha = `${String(today.getDate()).padStart(2, '0')}/${String(today.getMonth() + 1).padStart(2, '0')}/${today.getFullYear()}`;

const form = reactive({
  estado_id: null,
  municipio_id: null,
  parroquia_id: null,
  comuna_id: null,
  nombre_comuna_nueva: '',
  fecha: currentFecha,
  hubo_despliegue: null,
  instituciones: [],
  adultos_listado: 0,
  adultos_visitados: 0,
  vulnerables_detectados: 0,
  vulnerables_nuevos: 0,
  observaciones: ''
});

// Catálogos
const estados = ref([]);
const municipiosDisponibles = ref([]);
const parroquiasDisponibles = ref([]);
const comunasDisponibles = ref([]);
const institucionesList = ref([]);

// Filtros para select
const comunas = ref([]);

const headers = {
  Authorization: `Bearer ${LocalStorage.getItem('token')}`
};

// Carga Inicial
onMounted(async () => {
  try {
    // Cargar catálogos geográficos
    const resGeo = await axios.get(`${API_URL}/despliegues/catalogos/geografia`, { headers });
    estados.value = resGeo.data.estados;
    municipiosDisponibles.value = resGeo.data.municipios;
    parroquiasDisponibles.value = resGeo.data.parroquias;

    // Lógica de preselección por alcance geográfico
    if (estados.value.length === 1) {
      form.estado_id = estados.value[0].id;
      if (municipiosDisponibles.value.length === 1) {
        form.municipio_id = municipiosDisponibles.value[0].id;
        if (parroquiasDisponibles.value.length === 1) {
          form.parroquia_id = parroquiasDisponibles.value[0].id;
          await onParroquiaChange(form.parroquia_id);
        }
      }
    }

    // Cargar instituciones
    const resInst = await axios.get(`${API_URL}/despliegues/catalogos/instituciones`, { headers });
    institucionesList.value = resInst.data;

  } catch (error) {
    Notify.create({ message: 'Error cargando catálogos. Verifique su conexión.', color: 'negative' });
  }
});

// Computed properties para cascada
const municipiosFiltrados = computed(() => {
  return form.estado_id ? municipiosDisponibles.value.filter(m => m.estado_id === form.estado_id) : [];
});

const parroquiasFiltradas = computed(() => {
  return form.municipio_id ? parroquiasDisponibles.value.filter(p => p.municipio_id === form.municipio_id) : [];
});

// Eventos de Cambio
const onEstadoChange = () => {
  form.municipio_id = null;
  form.parroquia_id = null;
  form.comuna_id = null;
  if (municipiosFiltrados.value.length === 1) {
    form.municipio_id = municipiosFiltrados.value[0].id;
    onMunicipioChange();
  }
};

const onMunicipioChange = () => {
  form.parroquia_id = null;
  form.comuna_id = null;
  if (parroquiasFiltradas.value.length === 1) {
    form.parroquia_id = parroquiasFiltradas.value[0].id;
    onParroquiaChange(form.parroquia_id);
  }
};

const onParroquiaChange = async (val) => {
  form.comuna_id = null;
  if (!val) return;
  try {
    const res = await axios.get(`${API_URL}/despliegues/catalogos/comunas/${val}`, { headers });
    comunasDisponibles.value = res.data;
    comunas.value = res.data;
  } catch (error) {
    console.error(error);
  }
};

// Manejo de nueva Comuna
const filterComunas = (val, update) => {
  update(() => {
    if (val === '') {
      comunas.value = comunasDisponibles.value;
    } else {
      const needle = val.toLowerCase();
      comunas.value = comunasDisponibles.value.filter(
        v => v.nombre.toLowerCase().indexOf(needle) > -1
      );
    }
  });
};

const createComuna = (val, done) => {
  if (val.length > 0) {
    const upperval = val.toUpperCase();
    if (!comunasDisponibles.value.find(c => c.nombre === upperval)) {
      comunasDisponibles.value.push({
        id: upperval, // Usamos el nombre como id temporal para la selección
        nombre: upperval
      });
      form.nombre_comuna_nueva = upperval;
    }
    done(upperval, 'add-unique');
  }
};

// Validaciones
const vulnerablesValido = (value) => {
  if (value === null || value === undefined) return true;
  return value <= form.adultos_visitados;
};

const comunaRequerida = (val) => !!val || !!form.nombre_comuna_nueva;

// Reglas estáticas sin grupos (los grupos con arrays de strings causan recursión infinita en vuelidate)
const rules = {
  form: {
    estado_id: { required },
    municipio_id: { required },
    parroquia_id: { required },
    comuna_id: { comunaRequerida },
    fecha: { required },
    adultos_listado: { numeric, minValue: minValue(0) },
    adultos_visitados: { numeric, minValue: minValue(0) },
    vulnerables_detectados: { numeric, minValue: minValue(0), vulnerablesValido },
    vulnerables_nuevos: { numeric, minValue: minValue(0) }
  }
};

const v$ = useVuelidate(rules, { form });

// Computed para el estado de error por paso (usados en el template en lugar de v$.pasoN.$error)
const paso1Error = computed(() =>
  v$.value.form.estado_id.$error ||
  v$.value.form.municipio_id.$error ||
  v$.value.form.parroquia_id.$error ||
  v$.value.form.comuna_id.$error
);
const paso2Error = computed(() => v$.value.form.fecha.$error);
const paso3Error = computed(() =>
  v$.value.form.adultos_listado.$error ||
  v$.value.form.adultos_visitados.$error ||
  v$.value.form.vulnerables_detectados.$error ||
  v$.value.form.vulnerables_nuevos.$error
);

const siguientePaso = async () => {
  if (step.value === 1) {
    // Marcar solo los campos del paso 1
    v$.value.form.estado_id.$touch();
    v$.value.form.municipio_id.$touch();
    v$.value.form.parroquia_id.$touch();
    v$.value.form.comuna_id.$touch();
    const isStepValid =
      !v$.value.form.estado_id.$error &&
      !v$.value.form.municipio_id.$error &&
      !v$.value.form.parroquia_id.$error &&
      (!v$.value.form.comuna_id.$error || !!form.nombre_comuna_nueva);
    if (isStepValid) {
      step.value++;
    } else {
      Notify.create({ message: 'Por favor, complete los campos de ubicación', color: 'negative' });
    }
  } else if (step.value === 2) {
    v$.value.form.fecha.$touch();
    if (form.hubo_despliegue === null) {
      Notify.create({ message: 'Debe indicar si hubo despliegue', color: 'negative' });
      return;
    }
    if (!v$.value.form.fecha.$error) {
      if (!form.hubo_despliegue) {
        // Sin despliegue: saltar paso 3 e ir directo al 4
        step.value = 4;
      } else {
        if (form.instituciones.length === 0) {
          Notify.create({ message: 'Debe seleccionar al menos una institución si hubo despliegue', color: 'negative' });
          return;
        }
        step.value++;
      }
    } else {
      Notify.create({ message: 'Por favor, ingrese la fecha del despliegue', color: 'negative' });
    }
  } else if (step.value === 3) {
    v$.value.form.adultos_listado.$touch();
    v$.value.form.adultos_visitados.$touch();
    v$.value.form.vulnerables_detectados.$touch();
    v$.value.form.vulnerables_nuevos.$touch();
    const isStepValid =
      !v$.value.form.adultos_listado.$error &&
      !v$.value.form.adultos_visitados.$error &&
      !v$.value.form.vulnerables_detectados.$error &&
      !v$.value.form.vulnerables_nuevos.$error;
    if (isStepValid) {
      step.value++;
    } else {
      Notify.create({ message: 'Por favor, revise los errores en el formulario', color: 'negative' });
    }
  }
};

const submitForm = async () => {
  saving.value = true;
  try {
    const payload = { ...form };
    
    // Formatear la fecha de DD/MM/YYYY a YYYY-MM-DD para el backend
    if (payload.fecha && payload.fecha.includes('/')) {
      const [dia, mes, anio] = payload.fecha.split('/');
      payload.fecha = `${anio}-${mes}-${dia}`;
    }

    // Si la comuna es texto (id igual al nombre), limpiamos el comuna_id para que el backend la cree
    if (payload.comuna_id === payload.nombre_comuna_nueva) {
      payload.comuna_id = null;
    }

    const res = await axios.post(`${API_URL}/despliegues`, payload, { headers });
    Notify.create({ message: 'Despliegue guardado exitosamente', color: 'positive' });
    router.push('/admin/dashboard'); // O volver a un listado
  } catch (error) {
    const msg = error.response?.data?.error || 'Error al guardar despliegue';
    Notify.create({ message: msg, color: 'negative' });
  } finally {
    saving.value = false;
  }
};
</script>

<style scoped>
</style>
