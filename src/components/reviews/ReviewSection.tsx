"use client";

import { useState, useEffect } from "react";
import { useSession } from "next-auth/react";
import { Button } from "@/components/ui/Button";

interface Review {
    id: string;
    rating: number;
    comment: string;
    createdAt: string;
    user: {
        name: string | null;
        image: string | null;
    };
}

interface ReviewSectionProps {
    botProductId: string;
}

export function ReviewSection({ botProductId }: ReviewSectionProps) {
    const { data: session } = useSession();
    const [reviews, setReviews] = useState<Review[]>([]);
    const [loading, setLoading] = useState(true);
    const [isSubmitting, setIsSubmitting] = useState(false);
    
    // Form state
    const [rating, setRating] = useState(5);
    const [comment, setComment] = useState("");
    const [showForm, setShowForm] = useState(false);

    useEffect(() => {
        fetchReviews();
    }, [botProductId]);

    const fetchReviews = async () => {
        try {
            const res = await fetch(`/api/reviews?botProductId=${botProductId}`);
            const data = await res.json();
            if (data.reviews) {
                setReviews(data.reviews);
            }
        } catch (error) {
            console.error("Error fetching reviews:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!comment.trim()) return;

        setIsSubmitting(true);
        try {
            const res = await fetch("/api/reviews", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ botProductId, rating, comment }),
            });

            if (res.ok) {
                setComment("");
                setRating(5);
                setShowForm(false);
                fetchReviews(); // Refresh the list
            }
        } catch (error) {
            console.error("Error submitting review:", error);
        } finally {
            setIsSubmitting(false);
        }
    };

    const averageRating = reviews.length > 0 
        ? (reviews.reduce((acc, rev) => acc + rev.rating, 0) / reviews.length).toFixed(1)
        : "5.0";

    if (loading) {
        return <div className="animate-pulse h-32 bg-white/5 rounded-xl"></div>;
    }

    return (
        <div className="glass-card p-6 sm:p-10 border border-white/10 mt-12 w-full max-w-full">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-6 mb-10">
                <div>
                    <h3 className="text-2xl font-black text-white uppercase italic flex items-center gap-4">
                        <span className="text-amber-400">★</span>
                        Reseñas Verificadas
                    </h3>
                    <p className="text-text-muted mt-2 text-sm">
                        {reviews.length} {reviews.length === 1 ? 'valoración' : 'valoraciones'} · Media de <span className="text-white font-bold">{averageRating} / 5.0</span>
                    </p>
                </div>
                {session?.user && !showForm && (
                    <Button onClick={() => setShowForm(true)} variant="outline" className="border-brand/30 text-brand-light hover:bg-brand/10">
                        Escribir una reseña
                    </Button>
                )}
            </div>

            {showForm && (
                <form onSubmit={handleSubmit} className="mb-10 bg-white/[0.02] p-6 rounded-xl border border-white/5">
                    <div className="mb-4">
                        <label className="block text-xs font-bold text-text-muted uppercase tracking-widest mb-2">Puntuación</label>
                        <div className="flex gap-2">
                            {[1, 2, 3, 4, 5].map((star) => (
                                <button
                                    key={star}
                                    type="button"
                                    onClick={() => setRating(star)}
                                    className={`text-2xl transition-colors ${rating >= star ? 'text-amber-400' : 'text-white/20'}`}
                                >
                                    ★
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="mb-6">
                        <label className="block text-xs font-bold text-text-muted uppercase tracking-widest mb-2">Tu comentario</label>
                        <textarea
                            value={comment}
                            onChange={(e) => setComment(e.target.value)}
                            className="w-full bg-black/40 border border-white/10 rounded-lg p-4 text-white focus:outline-none focus:border-brand-light/50 min-h-[100px]"
                            placeholder="¿Qué te ha parecido el algoritmo?"
                            required
                        />
                    </div>
                    <div className="flex justify-end gap-4">
                        <Button type="button" variant="ghost" onClick={() => setShowForm(false)}>
                            Cancelar
                        </Button>
                        <Button type="submit" isLoading={isSubmitting} className="bg-brand hover:bg-brand-light">
                            Publicar Reseña
                        </Button>
                    </div>
                </form>
            )}

            <div className="space-y-6">
                {reviews.length === 0 ? (
                    <div className="text-center py-10 bg-white/[0.02] rounded-xl border border-white/5">
                        <p className="text-text-muted italic">Aún no hay reseñas. ¡Sé el primero en dejar tu opinión!</p>
                    </div>
                ) : (
                    reviews.map((review) => (
                        <div key={review.id} className="bg-white/[0.02] p-6 rounded-xl border border-white/5 flex gap-4">
                            <div className="w-10 h-10 rounded-full bg-brand/20 flex items-center justify-center flex-shrink-0 border border-brand/30">
                                <span className="text-brand-light font-bold uppercase">
                                    {review.user?.name?.charAt(0) || 'U'}
                                </span>
                            </div>
                            <div>
                                <div className="flex items-center gap-3 mb-1">
                                    <span className="font-bold text-white">{review.user?.name || 'Usuario'}</span>
                                    <span className="text-xs text-text-muted">
                                        {new Date(review.createdAt).toLocaleDateString('es-ES', { year: 'numeric', month: 'long', day: 'numeric' })}
                                    </span>
                                </div>
                                <div className="flex text-amber-400 text-sm mb-3">
                                    {'★'.repeat(review.rating)}{'☆'.repeat(5 - review.rating)}
                                </div>
                                <p className="text-text-muted text-sm leading-relaxed">{review.comment}</p>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}
