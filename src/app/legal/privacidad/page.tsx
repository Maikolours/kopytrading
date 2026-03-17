import Link from "next/link";

export default function PrivacidadPage() {
    return (
        <div className="min-h-screen pt-28 pb-20 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto">
                <Link href="/" className="text-brand-light hover:text-white text-sm flex items-center gap-2 mb-8 group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Inicio
                </Link>
                <h1 className="text-3xl font-bold text-white mb-8">Política de Privacidad</h1>
                <div className="glass-card border border-white/10 rounded-2xl p-8 space-y-8 text-text-muted text-sm leading-relaxed">

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">1. Responsable del Tratamiento</h2>
                        <p>KOPYTRADING gestiona este sitio web. Para cualquier consulta relacionada con el tratamiento de tus datos personales, puedes contactarnos a través de los canales oficiales habilitados en la plataforma.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">2. Datos que Recopilamos</h2>
                        <p>Recopilamos únicamente los datos estrictamente necesarios para prestarte el servicio:</p>
                        <ul className="list-disc list-inside mt-2 space-y-1">
                            <li>Dirección de correo electrónico (para identificación y entrega de productos)</li>
                            <li>Datos de pago (procesados por terceros seguros como Stripe/PayPal — no almacenamos datos de tarjeta)</li>
                            <li>Número de cuenta MT5 (únicamente para configuración del bot, no lo almacenamos en abierto)</li>
                            <li>Datos de uso del sitio web (cookies analíticas anonimizadas)</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">3. Finalidad del Tratamiento</h2>
                        <ul className="list-disc list-inside space-y-1">
                            <li>Gestión de compras y entrega de los archivos digitales adquiridos</li>
                            <li>Comunicaciones relacionadas con tu compra</li>
                            <li>Mejora del servicio y análisis estadístico anónimo</li>
                            <li>Cumplimiento de obligaciones legales</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">4. Base Legal</h2>
                        <p>El tratamiento de tus datos se basa en la ejecución del contrato (compra de producto digital) y, en su caso, en el consentimiento expreso que otorgas al usar el sitio.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">5. Tus Derechos</h2>
                        <p>En virtud del Reglamento General de Protección de Datos (RGPD) tienes derecho a:</p>
                        <ul className="list-disc list-inside mt-2 space-y-1">
                            <li><strong className="text-white">Acceso:</strong> Conocer qué datos tenemos sobre ti</li>
                            <li><strong className="text-white">Rectificación:</strong> Corregir datos inexactos</li>
                            <li><strong className="text-white">Supresión:</strong> Solicitar la eliminación de tus datos</li>
                            <li><strong className="text-white">Portabilidad:</strong> Recibir tus datos en formato legible</li>
                        </ul>
                        <p className="mt-2">Para ejercer tus derechos, puedes contactarnos a través de los canales oficiales habilitados en la plataforma.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">6. Conservación de Datos</h2>
                        <p>Conservamos tus datos durante el tiempo necesario para cumplir con la finalidad para la que fueron recogidos y con las obligaciones legales aplicables. En general, los datos de compra se conservan durante 5 años de conformidad con la normativa fiscal española.</p>
                    </section>

                    <p className="text-xs text-text-muted/60 border-t border-white/10 pt-4">Última actualización: Febrero 2026</p>
                </div>
            </div>
        </div>
    );
}
